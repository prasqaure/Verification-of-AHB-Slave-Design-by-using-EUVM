import esdl;
import uvm;
import std.stdio;

class ahb_seq_item(int DW, int AW): uvm_sequence_item {
  mixin uvm_object_utils;
  this(string name="") {
    super(name);
  }
  enum BW = DW / 8;
  @UVM_DEFAULT {
    @rand UBit!AW addr;
    @rand Bit!DW data;
    @UVM_BIN
    Bit!2 hwrite, hsize, hburst, htrans;
  }
  constraint! q{
    (addr >> 2) < 4;
    addr % BW == 0;
  } addrCst;
};

class ahb_sequence(int DW, int AW): uvm_sequence!(ahb_seq_item!(DW, AW)) {
  mixin uvm_object_utils;
  this(string name = "ahb_sequence") {
    super(name);
  }
  override void body() {
    auto req = ahb_seq_item!(DW, AW).type_id.create("req");
    start_item(req);
    finish_item(req);
    uvm_info("AHB_SEQ", "Sequence executed", UVM_MEDIUM);
  }
}

class ahb_sequencer(int DW, int AW): uvm_sequencer!(ahb_seq_item!(DW, AW)) {
  mixin uvm_component_utils;
  this(string name, uvm_component parent) {
    super(name, parent);
  }
}

class ahb_driver(int DW, int AW): uvm_driver!(ahb_seq_item!(DW, AW)) {
  mixin uvm_component_utils;
  AHBIntf!(DW, AW) ahb_if;
  this(string name, uvm_component parent) {
    super(name, parent);
    uvm_config_db!(AHBIntf!(DW, AW)).get(this, "", "ahb_if", ahb_if);
    assert(ahb_if !is null);
  }
  override void run_phase(uvm_phase phase) {
    while (true) {
      auto tr = seq_item_port.get_next_item();
      ahb_if.haddr = tr.addr;
      ahb_if.hwrite = tr.hwrite;
      ahb_if.hsize = tr.hsize;
      ahb_if.hburst = tr.hburst;
      ahb_if.htrans = 2;
      wait(ahb_if.hready == 1);
      seq_item_port.item_done();
    }
  }
}

class ahb_monitor(int DW, int AW): uvm_monitor {
  mixin uvm_component_utils;
  AHBIntf!(DW, AW) ahb_if;

  // Add variables to capture signal values
  Bit!AW addr;
  Bit!DW data;
  Bit!2 hwrite, hsize, hburst, htrans;

  this(string name, uvm_component parent) {
    super(name, parent);
    uvm_config_db!(AHBIntf!(DW, AW)).get(this, "", "ahb_if", ahb_if);
  }

  override void run_phase(uvm_phase phase) {
    while (true) {
      wait(ahb_if.hready == 1);  // Wait for hready to be high
      // Capture the values of the signals
      addr = ahb_if.haddr;
      data = ahb_if.hdata;  // Assuming hdata is part of the interface
      hwrite = ahb_if.hwrite;
      hsize = ahb_if.hsize;
      hburst = ahb_if.hburst;
      htrans = ahb_if.htrans;
    }
  }
}

class ahb_agent(int DW, int AW): uvm_agent {
  mixin uvm_component_utils;
  ahb_sequencer!(DW, AW) seqr;
  ahb_driver!(DW, AW) drv;
  ahb_monitor!(DW, AW) mon;
  this(string name, uvm_component parent) {
    super(name, parent);
  }
  override void build_phase(uvm_phase phase) {
    seqr = ahb_sequencer!(DW, AW).type_id.create("seqr", this);
    drv = ahb_driver!(DW, AW).type_id.create("drv", this);
    mon = ahb_monitor!(DW, AW).type_id.create("mon", this);
  }
}

class ahb_env(int DW, int AW): uvm_env {
  mixin uvm_component_utils;
  ahb_agent!(DW, AW) agent;
  this(string name, uvm_component parent) {
    super(name, parent);
  }
  override void build_phase(uvm_phase phase) {
    agent = ahb_agent!(DW, AW).type_id.create("agent", this);
  }
}

class ahb_test(int DW, int AW): uvm_test {
  mixin uvm_component_utils;
  ahb_env!(DW, AW) env;
  this(string name, uvm_component parent) {
    super(name, parent);
  }
  override void build_phase(uvm_phase phase) {
    env = ahb_env!(DW, AW).type_id.create("env", this);
  }
  override void run_phase(uvm_phase phase) {
    phase.raise_objection(this);
    auto seq = ahb_sequence!(DW, AW).type_id.create("seq");
    seq.start(env.agent.seqr);
    phase.drop_objection(this);
  }
}

void main() {
  run_test("ahb_test!(32, 32)");
}


//     ldc2 -relocation-model=pic -w -I/usr/include/dlang/ldc	\
//     -ofahb_adder ahb_adder.d					   \
//     -L-luvm-ldc-shared -L-lesdl-ldc-shared -L-lphobos2-ldc-shared	\
//     -L-ldruntime-ldc-shared -L-ldl -L-lstdc++
