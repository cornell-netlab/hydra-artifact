header eth_type2_t {
  bit<16> value;
}
header variables_t {
  bit<8> prev_vlan;
  bool vlan_valid;
  bit<7> _pad;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
}
struct hydra_metadata_t {
  bool reject0;
  bit<8> switch_vlan;
  bit<8> vlans;
  bit<8> vlans_var0;
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
control telemetryControl(inout hydra_header_t hydra_header,
                         inout hydra_metadata_t hydra_metadata) {
  action init_cp_vars(bit<8> switch_vlan)
    {
    hydra_metadata.switch_vlan = switch_vlan;
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
      (hydra_header.variables.vlan_valid && hydra_header.variables.prev_vlan==hydra_metadata.switch_vlan)
      {
      hydra_header.variables.vlan_valid = true;
    }else
    {
    hydra_header.variables.vlan_valid = false;
    }
    hydra_header.variables.prev_vlan = hydra_metadata.switch_vlan;
  }
}

