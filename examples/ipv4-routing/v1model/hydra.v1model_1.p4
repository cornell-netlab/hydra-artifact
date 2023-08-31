header eth_type2_t {
  bit<16> value;
}
header variables_t {
  bool to_reject;
  bit<7> _pad;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
}
struct hydra_metadata_t {
  bool reject0;
  bool firsthop;
  bool is_switch_leaf;
  bool lasthop;
}
parser CheckerHeaderParser(packet_in packet, out hydra_header_t hydra_header,
                           inout hydra_metadata_t hydra_metadata) {
  state start {
    packet.extract(hydra_header.eth_type);
    transition parse_variables;
  }
  state parse_variables {
    packet.extract(hydra_header.variables);
    transition accept;
  }
}
control CheckerHeaderDeparser(packet_out packet,
                              in hydra_header_t hydra_header) {
  apply
    {
    packet.emit(hydra_header.eth_type);
    packet.emit(hydra_header.variables);
  }
}
control initControl(inout hydra_header_t hydra_header,
                    inout hydra_metadata_t hydra_metadata) {
  action init_cp_vars(bool firsthop, bool is_switch_leaf, bool lasthop)
    {
    hydra_metadata.firsthop = firsthop;
    hydra_metadata.is_switch_leaf = is_switch_leaf;
    hydra_metadata.lasthop = lasthop;
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
    hydra_header.variables.to_reject = false;
    if (!hydra_metadata.is_switch_leaf)
      {
      hydra_header.variables.to_reject = true;
    }
  }
}
control telemetryControl(inout hydra_header_t hydra_header,
                         inout hydra_metadata_t hydra_metadata) {
  action init_cp_vars(bool firsthop, bool is_switch_leaf, bool lasthop)
    {
    hydra_metadata.firsthop = firsthop;
    hydra_metadata.is_switch_leaf = is_switch_leaf;
    hydra_metadata.lasthop = lasthop;
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
      (!hydra_metadata.lasthop && !hydra_metadata.firsthop && hydra_metadata.is_switch_leaf)
      {
      hydra_header.variables.to_reject = true;
    }
  }
}
control checkerControl(inout hydra_header_t hydra_header,
                       inout hydra_metadata_t hydra_metadata) {
  action init_cp_vars(bool firsthop, bool is_switch_leaf, bool lasthop)
    {
    hydra_metadata.firsthop = firsthop;
    hydra_metadata.is_switch_leaf = is_switch_leaf;
    hydra_metadata.lasthop = lasthop;
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
    if (!hydra_metadata.is_switch_leaf || hydra_header.variables.to_reject)
      {
      hydra_metadata.reject0 = true;
    }
    hydra_header.eth_type.setInvalid();
    hydra_header.variables.setInvalid();
  }
}

