import uvm;
import esdl;
import std.format;

class ahb_seq_item: uvm_sequence_item {
  mixin uvm_object_utils;

  this(string name="ahb_seq_item") {
    super(name);
  }

  @UVM_DEFAULT {
    @rand ubvec!12 addr;
    @rand ubvec!32 data;
    @rand ubvec!1 hwrite;
  }

  constraint! q{
    addr % 4 == 0;
    addr < 64;
  } cst_addr;
}

class ahb_seq: uvm_sequence!ahb_seq_item {
  mixin uvm_object_utils;

  this(string name="ahb_seq") {
    super(name);
  }

  @UVM_DEFAULT {
    @rand uint size;
  }

  constraint! q{
    size == 10;
  } cst_seq_size;

  override void body() {
    req = ahb_seq_item.type_id.create("req");
    for (size_t i = 0; i <= size; ++i) {
      wait_for_grant();
      req.randomize();
      ahb_seq_item cloned = cast(ahb_seq_item) req.clone();
      uvm_info("SEQ", cloned.sprint(), UVM_NONE);
      send_request(cloned);
    }
  }
}

class ahb_sequencer: uvm_sequencer!ahb_seq_item {
  mixin uvm_component_utils;

  this(string name, uvm_component parent = null) {
    super(name, parent);
    uvm_info("SEQ", "Sequencer created", UVM_NONE);
  }
}

class ahb_driver: uvm_driver!(ahb_seq_item) {
  mixin uvm_component_utils;

  AhbIf ahb_if;
  ahb_seq_item current_req;

  this(string name, uvm_component parent = null) {
    super(name, parent);
  }

  override void build_phase(uvm_phase phase) {
    super.build_phase(phase);
    uvm_config_db!AhbIf.get(this, "", "ahb_if", ahb_if);
    assert (ahb_if !is null);
    uvm_info("DRV", "Driver created and interface connected", UVM_NONE);
  }

  override void run_phase(uvm_phase phase) {
    super.run_phase(phase);

    while (!ahb_if.HRESETn)
      wait(ahb_if.HCLK.posedge());

    while (true) {

      seq_item_port.get_next_item(current_req);


      ahb_if.HADDR  = current_req.addr;
      ahb_if.HWRITE = current_req.hwrite;
      ahb_if.HTRANS = true;
      ahb_if.HSEL   = true;

      if (current_req.hwrite)
        ahb_if.HWDATA = current_req.data;

      do {
        wait(ahb_if.HCLK.posedge());
      } while (!ahb_if.HREADY);

      if (!current_req.hwrite)
        current_req.data = ahb_if.HRDATA;

      uvm_info("DRIVER", current_req.sprint(), UVM_NONE);

      ahb_if.HTRANS = true;
      ahb_if.HSEL   = false;

      seq_item_port.item_done();
      uvm_info("DRIVER", "run_phase 3", UVM_NONE);
    }
  }
}

class ahb_monitor: uvm_monitor {
  mixin uvm_component_utils;

  AhbIf ahb_if;
  uvm_analysis_port!(ahb_seq_item) item_port;

  this(string name, uvm_component parent = null) {
    super(name, parent);
  }

  override void build_phase(uvm_phase phase) {
    super.build_phase(phase);
    item_port = new uvm_analysis_port!(ahb_seq_item)("item_port", this);
    uvm_config_db!AhbIf.get(this, "", "ahb_if", ahb_if);
    assert(ahb_if !is null);
  }

  override void run_phase(uvm_phase phase) {
    super.run_phase(phase);

    while (!ahb_if.HRESETn)
      wait(ahb_if.HCLK.posedge());

    while (true) {
      wait(ahb_if.HCLK.posedge());

      if (ahb_if.HTRANS == true && ahb_if.HSEL && ahb_if.HREADY) {
        auto item = new ahb_seq_item();
        item.addr = ahb_if.HADDR;
        item.hwrite = ahb_if.HWRITE;
        item.data = item.hwrite ? ahb_if.HWDATA : ahb_if.HRDATA;
        uvm_info("MON", item.sprint(), UVM_NONE);
        item_port.write(item);
      }
    }
  }
}

class ahb_scoreboard: uvm_component {
  mixin uvm_component_utils;

  this(string name, uvm_component parent = null) {
    super(name, parent);
  }

  uvm_analysis_imp!(ahb_seq_item, ahb_scoreboard) mon_export;
  uint[16] memory;

  override void build_phase(uvm_phase phase) {
    super.build_phase(phase);
    mon_export = new uvm_analysis_imp!(ahb_seq_item, ahb_scoreboard)("mon_export", this);
  }

  void write(ahb_seq_item item) {
    uint index = item.addr >> 2;
    if (item.hwrite) {
      memory[index] = item.data;
      uvm_info("SB", format("WRITE confirmed: addr=0x%X data=0x%X", item.addr, item.data), UVM_NONE);
    } else {
      uint expected = memory[index];
      if (expected != item.data) {
        uvm_error("SB", format("READ mismatch at addr=0x%X: expected=0x%X, got=0x%X", item.addr, expected, item.data));
      } else {
        uvm_info("SB", format("READ verified: addr=0x%X data=0x%X", item.addr, item.data), UVM_NONE);
      }
    }
  }
}

class ahb_agent: uvm_agent {
  @UVM_BUILD {
    ahb_sequencer sequencer;
    ahb_driver    driver;
    ahb_monitor   monitor;
  }

  mixin uvm_component_utils;

  this(string name, uvm_component parent = null) {
    super(name, parent);
  }

  override void connect_phase(uvm_phase phase) {
    driver.seq_item_port.connect(sequencer.seq_item_export);
  }
}

class ahb_env: uvm_env {
  mixin uvm_component_utils;

  @UVM_BUILD {
    ahb_agent agent;
    ahb_scoreboard scoreboard;
  }

  override void connect_phase(uvm_phase phase) {
    agent.monitor.item_port.connect(scoreboard.mon_export);
  }

  this(string name, uvm_component parent) {
    super(name, parent);
  }
}

class AhbIf: VlInterface {
  Port!(Signal!(ubvec!1)) HCLK;
  Port!(Signal!(ubvec!1)) HRESETn;

  VlPort!(1) HSEL;
  VlPort!(1) HWRITE;
  VlPort!(1) HREADY;
  VlPort!(2) HTRANS;
  VlPort!(12) HADDR;
  VlPort!(32) HWDATA;
  VlPort!(32) HRDATA;
}

class ahb_tb_top: Entity {
  import Vahb_design_euvm;
  import esdl.intf.verilator.verilated;
  import esdl.intf.verilator.trace;

  AhbIf ahbSlave;
  VerilatedVcdD _trace;
  Signal!(ubvec!1) clk;
  Signal!(ubvec!1) rstn;
  DVahb_design dut;

  void opentrace(string vcdname) {
    if (_trace is null) {
      _trace = new VerilatedVcdD();
      dut.trace(_trace, 99);
      _trace.open(vcdname);
    }
  }

  void closetrace() {
    if (_trace !is null) {
      _trace.close();
      _trace = null;
    }
  }

  override void doConnect() {
    ahbSlave.HCLK(clk);
    ahbSlave.HRESETn(rstn);
    ahbSlave.HSEL(dut.HSEL);
    ahbSlave.HWRITE(dut.HWRITE);
    ahbSlave.HREADY(dut.HREADY);
    ahbSlave.HTRANS(dut.HTRANS);
    ahbSlave.HADDR(dut.HADDR);
    ahbSlave.HWDATA(dut.HWDATA);
    ahbSlave.HRDATA(dut.HRDATA);
  }

  override void doBuild() {
    dut = new DVahb_design();
    traceEverOn(true);
    opentrace("ahb_design.vcd");
  }

  Task!stimulateClk stimulateClkTask;
  Task!stimulateRst stimulateRstTask;

  void stimulateClk() {
    clk = false;
    for (size_t i = 0; i != 1000000; ++i) {
      clk = false;
      dut.HCLK = false;
      wait(2.nsec);
      dut.eval();
      if (_trace !is null)
        _trace.dump(getSimTime().getVal());
      wait(8.nsec);
      clk = true;
      dut.HCLK = true;
      wait(2.nsec);
      dut.eval();
      if (_trace !is null) {
        _trace.dump(getSimTime().getVal());
        _trace.flush();
      }
      wait(8.nsec);
    }
  }

  void stimulateRst() {
    rstn = false;
    dut.HRESETn = false;
    wait(100.nsec);
    rstn = true;
    dut.HRESETn = true;
  }
}

class random_test: uvm_test {
  mixin uvm_component_utils;

  this(string name = "", uvm_component parent = null) {
    super(name, parent);
  }

  @UVM_BUILD {
    ahb_env env;
  }

  override void run_phase(uvm_phase phase) {
    phase.raise_objection(this);
    foreach (i; 0 .. 10) {  
        auto rand_sequence = ahb_seq.type_id.create("ahb_seq");
        rand_sequence.randomize();
        rand_sequence.start(env.agent.sequencer, null);
        uvm_info("TEST", format("Transaction %d started", i), UVM_NONE);
    }
    phase.drop_objection(this);
}

}

class ahb_tb: uvm_tb {
  ahb_tb_top top = new ahb_tb_top();
  override void initial() {
    uvm_config_db!(AhbIf).set(null, "uvm_test_top.env.agent.driver", "ahb_if", top.ahbSlave);
    uvm_config_db!(AhbIf).set(null, "uvm_test_top.env.agent.monitor", "ahb_if", top.ahbSlave);
  }
}

void main(string[] args) {
  import std.stdio;
  uint random_seed;

  CommandLine cmdl = new CommandLine(args);

  if (cmdl.plusArgs("random_seed=" ~ "%d", random_seed))
    writeln("Using random_seed: ", random_seed);
  else
    random_seed = 1;

  auto tb = new ahb_tb;
  tb.multicore(0, 1);
  tb.elaborate("tb", args);
  tb.set_seed(random_seed);
  tb.start();
}
