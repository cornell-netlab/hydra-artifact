header eth_type2_t {
  bit<16> value;
}
header variables_t {
  bool loop;
  bit<7> _pad;
}
header switches_preamble_t {
  bit<8> num_items_switches;
}
header switches_item_t {
  bit<32> value;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
  switches_preamble_t switches_preamble;
  switches_item_t[3] switches;
}
struct hydra_metadata_t {
  bool reject0;
  bit<8> num_list_items;
  bit<16> switch_id;
}
parser CheckerHeaderParser(packet_in packet, out hydra_header_t hydra_header,
                           inout hydra_metadata_t hydra_metadata) {
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
    hydra_metadata.num_list_items =
    hydra_header.switches_preamble.num_items_switches;
    transition select(hydra_metadata.num_list_items) {
      0: accept;
      default: parse_switches;
    }
  }
  state parse_switches
    {
    packet.extract(hydra_header.switches.next);
    hydra_metadata.num_list_items = hydra_metadata.num_list_items-1;
    transition select(hydra_metadata.num_list_items) {
      0: accept;
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
  table tb_init_cp_vars
    {
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
    hydra_header.eth_type.setValid();
    hydra_header.eth_type.value = ETHERTYPE_CHECKER;
    hydra_header.variables.setValid();
    hydra_header.switches_preamble.num_items_switches = 0;
    hydra_header.variables.loop = false;
  }
}
control telemetryControl(inout hydra_header_t hydra_header,
                         inout hydra_metadata_t hydra_metadata) {
  action init_cp_vars(bit<16> switch_id)
    {
    hydra_metadata.switch_id = switch_id;
  }
  table tb_init_cp_vars
    {
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
    if
      (hydra_header.switches[0].isValid() && hydra_metadata.switch_id==hydra_header.switches[
                                                                    0] || hydra_header.switches[1].isValid() && hydra_metadata.switch_id==hydra_header.switches[
                                                                    1] || hydra_header.switches[2].isValid() && hydra_metadata.switch_id==hydra_header.switches[
                                                                    2])
      {
      hydra_header.variables.loop = true;
    }
    hydra_header.switches.push_front(1);
    hydra_header.switches[0].setValid();
    hydra_header.switches[0].value = hydra_metadata.switch_id;
    hydra_header.switches_preamble.num_items_switches =
    hydra_header.switches_preamble.num_items_switches+1;
  }
}
control checkerControl(inout hydra_header_t hydra_header,
                       inout hydra_metadata_t hydra_metadata) {
  action init_cp_vars(bit<16> switch_id)
    {
    hydra_metadata.switch_id = switch_id;
  }
  table tb_init_cp_vars
    {
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

