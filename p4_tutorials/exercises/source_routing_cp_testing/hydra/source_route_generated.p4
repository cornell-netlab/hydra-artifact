#include <v1model.p4> 

#define ETHERTYPE_CHECKER 0x5678;


header eth_type2_t {
  bit<16> value;
}
header variables_t {
  bit<7> index;
  bool to_reject;
}
header expected_path_preamble_t {
  bit<8> num_items_expected_path;
}
header expected_path_item_t {
  bit<16> value;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
  expected_path_preamble_t expected_path_preamble;
  expected_path_item_t[3] expected_path;
}
struct hydra_metadata_t {
  bool reject0;
  bit<8> num_list_items;
  bit<16> expected_s1_dict;
  bit<16> expected_s2_dict;
  bit<16> expected_s3_dict;
  bit<16> switch_id;
  bit<32> expected_s1_dict_var0;
  bit<32> expected_s2_dict_var0;
  bit<32> expected_s3_dict_var0;
}
parser CheckerHeaderParser(packet_in packet, out hydra_header_t hydra_header,
                           inout hydra_metadata_t hydra_metadata) {
  state start {
    packet.extract(hydra_header.eth_type);
    transition parse_variables;
  }
  state parse_variables {
    packet.extract(hydra_header.variables);
    transition parse_expected_path_preamble;
  }
  state parse_expected_path_preamble
    {
    packet.extract(hydra_header.expected_path_preamble);
    hydra_metadata.num_list_items =
    hydra_header.expected_path_preamble.num_items_expected_path;
    transition select(hydra_metadata.num_list_items) {
      0: accept;
      default: parse_expected_path;
    }
  }
  state parse_expected_path
    {
    packet.extract(hydra_header.expected_path.next);
    hydra_metadata.num_list_items = hydra_metadata.num_list_items-1;
    transition select(hydra_metadata.num_list_items) {
      0: accept;
      default: parse_expected_path;
    }
  }
}
control CheckerHeaderDeparser(packet_out packet,
                              in hydra_header_t hydra_header) {
  apply
    {
    packet.emit(hydra_header.eth_type);
    packet.emit(hydra_header.variables);
    packet.emit(hydra_header.expected_path_preamble);
    packet.emit(hydra_header.expected_path);
  }
}
control initControl(in ipv4_t ipv4,
                    inout hydra_header_t hydra_header,
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
  action lkp_cp_dict_expected_s1_dict(bit<16> expected_s1_dict)
    {
    hydra_metadata.expected_s1_dict = expected_s1_dict;
  }
  table tbl_lkp_cp_dict_expected_s1_dict
    {
    key = {
      hydra_metadata.expected_s1_dict_var0: lpm;
    }
    actions = {
      lkp_cp_dict_expected_s1_dict;
    }
    size = 64;
  }
  action lkp_cp_dict_expected_s2_dict(bit<16> expected_s2_dict)
    {
    hydra_metadata.expected_s2_dict = expected_s2_dict;
  }
  table tbl_lkp_cp_dict_expected_s2_dict
    {
    key = {
      hydra_metadata.expected_s2_dict_var0: lpm;
    }
    actions = {
      lkp_cp_dict_expected_s2_dict;
    }
    size = 64;
  }
  action lkp_cp_dict_expected_s3_dict(bit<16> expected_s3_dict)
    {
    hydra_metadata.expected_s3_dict = expected_s3_dict;
  }
  table tbl_lkp_cp_dict_expected_s3_dict
    {
    key = {
      hydra_metadata.expected_s3_dict_var0: lpm;
    }
    actions = {
      lkp_cp_dict_expected_s3_dict;
    }
    size = 64;
  }
  apply
    {
    tb_init_cp_vars.apply();
    hydra_header.eth_type.setValid();
    hydra_header.eth_type.value = ETHERTYPE_CHECKER;
    hydra_header.variables.setValid();
    hydra_header.expected_path_preamble.num_items_expected_path = 0;
    hydra_metadata.expected_s3_dict_var0 = ipv4.dstAddr;
    tbl_lkp_cp_dict_expected_s3_dict.apply();
    hydra_header.expected_path.push_front(1);
    hydra_header.expected_path[0].setValid();
    hydra_header.expected_path[0].value = hydra_metadata.expected_s3_dict;
    hydra_header.expected_path_preamble.num_items_expected_path =
    hydra_header.expected_path_preamble.num_items_expected_path+1;
    hydra_metadata.expected_s2_dict_var0 = ipv4.dstAddr;
    tbl_lkp_cp_dict_expected_s2_dict.apply();
    hydra_header.expected_path.push_front(1);
    hydra_header.expected_path[0].setValid();
    hydra_header.expected_path[0].value = hydra_metadata.expected_s2_dict;
    hydra_header.expected_path_preamble.num_items_expected_path =
    hydra_header.expected_path_preamble.num_items_expected_path+1;
    hydra_metadata.expected_s1_dict_var0 = ipv4.dstAddr;
    tbl_lkp_cp_dict_expected_s1_dict.apply();
    hydra_header.expected_path.push_front(1);
    hydra_header.expected_path[0].setValid();
    hydra_header.expected_path[0].value = hydra_metadata.expected_s1_dict;
    hydra_header.expected_path_preamble.num_items_expected_path =
    hydra_header.expected_path_preamble.num_items_expected_path+1;
    hydra_header.variables.index = 0;
    hydra_header.variables.to_reject = false;
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
      (hydra_header.expected_path[hydra_header.variables.index].value!=hydra_metadata.switch_id)
      {
      hydra_header.variables.to_reject = true;
    }else
    {
    if (hydra_header.variables.index<3)
      {
      hydra_header.variables.index = hydra_header.variables.index+1;
    }else {
    hydra_header.variables.to_reject = true;
    }
    }
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
    if (hydra_header.variables.to_reject) {
      hydra_metadata.reject0 = true;
    }
    hydra_header.eth_type.setInvalid();
    hydra_header.variables.setInvalid();
    hydra_header.expected_path_preamble.setInvalid();
    hydra_header.expected_path[0].setInvalid();
    hydra_header.expected_path[1].setInvalid();
    hydra_header.expected_path[2].setInvalid();
  }
}

