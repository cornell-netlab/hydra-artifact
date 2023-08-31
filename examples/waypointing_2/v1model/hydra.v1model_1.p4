header eth_type2_t {
  bit<16> value;
}
header variables_t {
  
}
header paths_preamble_t {
  bit<8> num_items_paths;
}
header paths_item_t {
  bit<16> value;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
  paths_preamble_t paths_preamble;
  paths_item_t[3] paths;
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
    transition parse_paths_preamble;
  }
  state parse_paths_preamble
    {
    packet.extract(hydra_header.paths_preamble);
    hydra_metadata.num_list_items =
    hydra_header.paths_preamble.num_items_paths;
    transition select(hydra_metadata.num_list_items) {
      0: accept;
      default: parse_paths;
    }
  }
  state parse_paths
    {
    packet.extract(hydra_header.paths.next);
    hydra_metadata.num_list_items = hydra_metadata.num_list_items-1;
    transition select(hydra_metadata.num_list_items) {
      0: accept;
      default: parse_paths;
    }
  }
}
control CheckerHeaderDeparser(packet_out packet,
                              in hydra_header_t hydra_header) {
  apply
    {
    packet.emit(hydra_header.eth_type);
    packet.emit(hydra_header.variables);
    packet.emit(hydra_header.paths_preamble);
    packet.emit(hydra_header.paths);
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
    hydra_header.paths_preamble.num_items_paths = 0;
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
    hydra_header.paths.push_front(1);
    hydra_header.paths[0].setValid();
    hydra_header.paths[0].value = hydra_metadata.switch_id;
    hydra_header.paths_preamble.num_items_paths =
    hydra_header.paths_preamble.num_items_paths+1;
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
    bool found = false;
    bit<16> waypoint = 3;
    if
      (hydra_header.paths[0].isValid() && waypoint==hydra_header.paths[0] || hydra_header.paths[1].isValid() && waypoint==hydra_header.paths[
                                                                    1] || hydra_header.paths[2].isValid() && waypoint==hydra_header.paths[
                                                                    2])
      {
      found = true;
    }
    if (!found) {
      hydra_metadata.reject0 = true;
    }
    hydra_header.eth_type.setInvalid();
    hydra_header.variables.setInvalid();
    hydra_header.paths_preamble.setInvalid();
    hydra_header.paths[0].setInvalid();
    hydra_header.paths[1].setInvalid();
    hydra_header.paths[2].setInvalid();
  }
}

