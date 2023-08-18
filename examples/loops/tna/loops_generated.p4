#define ETHERTYPE_CHECKER 0x5678

parser CheckerHeaderParser(packet_in packet, out hydra_header_t hydra_header,
                           inout hydra_metadata_t hydra_metadata) {
  ParserCounter() switches_counter;
  state start {
    packet.extract(hydra_header.eth_type);
    transition parse_variables;
  }
  state parse_variables {
    packet.extract(hydra_header.variables);
    transition parse_switches_preamble;
  }
  state parse_switches_preamble
    {
    packet.extract(hydra_header.switches_preamble);
    switches_counter.set(hydra_header.switches_preamble.num_items_switches);
    transition select(switches_counter.is_zero()) {
      true: accept;
      default: parse_switches;
    }
  }
  state parse_switches
    {
    packet.extract(hydra_header.switches.next);
    switches_counter.decrement(1);
    transition select(switches_counter.is_zero()) {
      true: accept;
      default: parse_switches;
    }
  }
}
control CheckerHeaderDeparser(packet_out packet,
                              in hydra_header_t hydra_header) {
  apply
    {
    packet.emit(hydra_header.eth_type);
    packet.emit(hydra_header.variables);
    packet.emit(hydra_header.switches_preamble);
    packet.emit(hydra_header.switches);
  }
}
control initControl(inout hydra_header_t hydra_header,
                    inout hydra_metadata_t hydra_metadata) {
  action init_cp_vars(bit<16> switch_id)
    {
    hydra_metadata.switch_id = switch_id;
  }
  table tb_init_cp_vars {
    key = {
      
    }
    actions = {
      init_cp_vars;
    }
    size = 2;
  }
  apply
    {
    tb_init_cp_vars.apply();
    hydra_header.eth_type.setValid();
    hydra_header.eth_type.value = ETHERTYPE_CHECKER;
    hydra_header.variables.setValid();
    hydra_header.variables.loop = false;
    hydra_header.switches_preamble.setValid();
    hydra_header.switches_preamble.num_items_switches = 0;
  }
}
control telemetryControl(inout hydra_header_t hydra_header,
                         inout hydra_metadata_t hydra_metadata) {
  action init_cp_vars(bit<16> switch_id)
    {
    hydra_metadata.switch_id = switch_id;
  }
  table tb_init_cp_vars {
    key = {
      
    }
    actions = {
      init_cp_vars;
    }
    size = 2;
  }
  apply
    {
    tb_init_cp_vars.apply();
    if
      (hydra_header.switches[0].isValid() && hydra_metadata.switch_id==hydra_header.switches[
                                                                    0].value || hydra_header.switches[1].isValid() && hydra_metadata.switch_id==hydra_header.switches[
                                                                    1].value || hydra_header.switches[2].isValid() && hydra_metadata.switch_id==hydra_header.switches[
                                                                    2].value)
      {
      hydra_header.variables.loop = true;
    }
    hydra_header.switches.push_front(1);
    hydra_header.switches[0].setValid();
    hydra_header.switches[0].value = hydra_metadata.switch_id;
    hydra_header.switches_preamble.num_items_switches = hydra_header.switches_preamble.num_items_switches + 1;
  }
}
control checkerControl(inout hydra_header_t hydra_header,
                       inout hydra_metadata_t hydra_metadata) {
  action init_cp_vars(bit<16> switch_id)
    {
    hydra_metadata.switch_id = switch_id;
  }
  table tb_init_cp_vars {
    key = {
        hydra_header.eth_type.isValid(): exact; 
    }
    actions = {
      init_cp_vars;
    }
    size = 2;
  }
  apply
    {
    tb_init_cp_vars.apply();
    if (hydra_header.variables.loop) {
      hydra_metadata.reject0 = true;
    }

    hydra_header.eth_type.setInvalid();
    hydra_header.variables.setInvalid();
    hydra_header.switches_preamble.setInvalid();
    hydra_header.switches[0].setInvalid();
    hydra_header.switches[1].setInvalid();
    hydra_header.switches[2].setInvalid();
  }
}