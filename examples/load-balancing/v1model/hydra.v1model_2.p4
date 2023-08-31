header eth_type2_t {
  bit<16> value;
}
header variables_t {
  
}
header left_loads_preamble_t {
  bit<8> num_items_left_loads;
}
header left_loads_item_t {
  bit<32> value;
}
header right_loads_preamble_t {
  bit<8> num_items_right_loads;
}
header right_loads_item_t {
  bit<32> value;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
  left_loads_preamble_t left_loads_preamble;
  left_loads_item_t[4] left_loads;
  right_loads_preamble_t right_loads_preamble;
  right_loads_item_t[4] right_loads;
}
struct hydra_metadata_t {
  bool reject0;
  bit<8> num_list_items;
  bool is_uplink;
  bit<8> left_port;
  bit<8> right_port;
  bit<32> thresh;
  bit<8> is_uplink_var0;
}
parser CheckerHeaderParser(packet_in packet, out hydra_header_t hydra_header,
                           inout hydra_metadata_t hydra_metadata) {
  state start {
    packet.extract(hydra_header.eth_type);
    transition parse_variables;
  }
  state parse_variables {
    packet.extract(hydra_header.variables);
    transition parse_left_loads_preamble;
  }
  state parse_left_loads_preamble
    {
    packet.extract(hydra_header.left_loads_preamble);
    hydra_metadata.num_list_items =
    hydra_header.left_loads_preamble.num_items_left_loads;
    transition select(hydra_metadata.num_list_items) {
      0: parse_right_loads_preamble;
      default: parse_left_loads;
    }
  }
  state parse_right_loads_preamble
    {
    packet.extract(hydra_header.right_loads_preamble);
    hydra_metadata.num_list_items =
    hydra_header.right_loads_preamble.num_items_right_loads;
    transition select(hydra_metadata.num_list_items) {
      0: accept;
      default: parse_right_loads;
    }
  }
  state parse_left_loads
    {
    packet.extract(hydra_header.left_loads.next);
    hydra_metadata.num_list_items = hydra_metadata.num_list_items-1;
    transition select(hydra_metadata.num_list_items) {
      0: parse_right_loads_preamble;
      default: parse_left_loads;
    }
  }
  state parse_right_loads
    {
    packet.extract(hydra_header.right_loads.next);
    hydra_metadata.num_list_items = hydra_metadata.num_list_items-1;
    transition select(hydra_metadata.num_list_items) {
      0: accept;
      default: parse_right_loads;
    }
  }
}
control CheckerHeaderDeparser(packet_out packet,
                              in hydra_header_t hydra_header) {
  apply
    {
    packet.emit(hydra_header.eth_type);
    packet.emit(hydra_header.variables);
    packet.emit(hydra_header.left_loads_preamble);
    packet.emit(hydra_header.left_loads);
    packet.emit(hydra_header.right_loads_preamble);
    packet.emit(hydra_header.right_loads);
  }
}
control telemetryControl(inout hydra_header_t hydra_header,
                         inout hydra_metadata_t hydra_metadata) {
  action init_cp_vars(bit<8> left_port, bit<8> right_port, bit<32> thresh)
    {
    hydra_metadata.left_port = left_port;
    hydra_metadata.right_port = right_port;
    hydra_metadata.thresh = thresh;
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
  action lkp_cp_dict_is_uplink(bool is_uplink)
    {
    hydra_metadata.is_uplink = is_uplink;
  }
  table tbl_lkp_cp_dict_is_uplink
    {
    key = {
      hydra_metadata.is_uplink_var0: exact;
    }
    actions = {
      lkp_cp_dict_is_uplink;
    }
    size = 64;
  }
  apply
    {
    tb_init_cp_vars.apply();
    hydra_metadata.is_uplink_var0 = standard_metadata.egress_port;
    tbl_lkp_cp_dict_is_uplink.apply();
    if (hydra_metadata.is_uplink)
      {
      if (standard_metadata.egress_port==hydra_metadata.left_port)
        {
        hydra_sensor.left_load =
        hydra_sensor.left_load+standard_metadata.packet_length;
      }else
      {
      if (standard_metadata.egress_port==hydra_metadata.right_port)
        {
        hydra_sensor.right_load =
        hydra_sensor.right_load+standard_metadata.packet_length;
      }
      }
    }
    hydra_header.left_loads.push_front(1);
    hydra_header.left_loads[0].setValid();
    hydra_header.left_loads[0].value = hydra_sensor.left_load;
    hydra_header.left_loads_preamble.num_items_left_loads =
    hydra_header.left_loads_preamble.num_items_left_loads+1;
    hydra_header.right_loads.push_front(1);
    hydra_header.right_loads[0].setValid();
    hydra_header.right_loads[0].value = hydra_sensor.right_load;
    hydra_header.right_loads_preamble.num_items_right_loads =
    hydra_header.right_loads_preamble.num_items_right_loads+1;
  }
}

