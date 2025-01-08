`timescale 1ns / 1ps

module memory_tb;

  // Clock and reset signals
  reg clk;
  reg reset;

  // DUT signals
  reg wr_en;
  reg rd_en;
  reg [3:0] addrr;
  reg [3:0] addrw;
  reg [15:0] wdata;
  wire [15:0] rdata;

  // Instantiate DUT
  memory dut (
    .clk(clk),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .addrr(addrr),
    .addrw(addrw),
    .wdata(wdata),
    .rdata(rdata)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Reset generation
  initial begin
    reset = 1;
    #10 reset = 0;
  end

  // Coverage points and assertions for verification
  // Coverage for write and read enable signals, address range, and data values
  covergroup mem_access_cg @(posedge clk);
    coverpoint wr_en;
    coverpoint rd_en;
    coverpoint addrw {bins addrw_bins[] = {[0:15]};}
    coverpoint addrr {bins addrr_bins[] = {[0:15]};}
    coverpoint wdata;
    coverpoint rdata;
  endgroup

  // Assertions to ensure correct memory behavior
  
    // Define the combined property
property combined_checks;
  @(posedge clk) !(wr_en && rd_en) &&       // wr_en and rd_en not both asserted
                 (addrw < 16 && addrr < 16) && // Addresses within valid range
                 (rd_en || (rdata == rdata)); // rdata stable if rd_en is not asserted
endproperty

// Assert the property with error message on failure
assert property (combined_checks)
  else $error("Error: Combined assertion failed - check for write-read enable conflict, address range, or rdata stability.");

 

  // Instantiate coverage group
  mem_access_cg mem_cov = new();



  // Driver class to drive inputs to DUT
  class mem_driver;
    // Task to drive write operation
    task drive_write(input [3:0] address, input [15:0] data);
      wr_en = 1;
      rd_en = 0;
      addrw = address;
      wdata = data;
      @(posedge clk);
      wr_en = 0;
    endtask

    // Task to drive read operation
    task drive_read(input [3:0] address);
      rd_en = 1;
      wr_en = 0;
      addrr = address;
      @(posedge clk);
      rd_en = 0;
    endtask
  endclass

  // Monitor class to observe DUT outputs
  class mem_monitor;
    // Observed read data and address for comparison
    reg [15:0] observed_rdata;
    reg [3:0] observed_address;

    // Task to capture read output
    task monitor_read();
      if (rd_en) begin
        observed_rdata = rdata;
        observed_address = addrr;
      end
    endtask
  endclass

  // Scoreboard class for checking functionality
  class mem_scoreboard;
    // Reference memory model for checking expected behavior
    reg [15:0] ref_mem [0:15];

    // Task to check write operation
    task check_write(input [3:0] address, input [15:0] data);
      ref_mem[address] = data;
    endtask

    // Task to check read operation
    task check_read(input [3:0] address, input [15:0] observed_data);
      if (observed_data !== ref_mem[address]) begin
        $error("Error: Read data mismatch at address %0d. Expected: %0h, Got: %0h", address, ref_mem[address], observed_data);
      end
    endtask
  endclass

  // Test class to run multiple test cases
  class mem_test;
    mem_driver driver;
    mem_monitor monitor;
    mem_scoreboard scoreboard;

    // Constructor
    function new();
      driver = new();
      monitor = new();
      scoreboard = new();
    endfunction

    // Task to run basic write and read test
    task basic_test();
      driver.drive_write(4'hA, 16'hABCD);  // Write data at address A
      scoreboard.check_write(4'hA, 16'hABCD);

      driver.drive_read(4'hA);             // Read data from address A
      monitor.monitor_read();
      scoreboard.check_read(4'hA, monitor.observed_rdata);
    endtask

    // Task to run a test for each address location
    task address_sweep_test();
      for (int i = 0; i < 16; i++) begin
        driver.drive_write(i, i);        // Write data equal to address
        scoreboard.check_write(i, i);

        driver.drive_read(i);            // Read back data from the same address
        monitor.monitor_read();
        scoreboard.check_read(i, monitor.observed_rdata);
      end
    endtask

    // Task to run random tests for coverage
    task random_test(int num_tests);
      for (int i = 0; i < num_tests; i++) begin
        int rand_addr = $urandom_range(0, 15);
        int rand_data = $urandom;

        driver.drive_write(rand_addr, rand_data);
        scoreboard.check_write(rand_addr, rand_data);

        driver.drive_read(rand_addr);
        monitor.monitor_read();
        scoreboard.check_read(rand_addr, monitor.observed_rdata);
      end
    endtask
  endclass

  // Instantiate test class and run test cases
  mem_test test;

  initial begin
    test = new();
    test.basic_test();
    test.address_sweep_test();
    test.random_test(100);
    $finish;
  end

endmodule




