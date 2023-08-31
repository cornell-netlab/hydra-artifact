header eth_type2_t {
  bit<16> value;
}
header variables_t {
  bit<8> tenant;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
}
struct hydra_metadata_t {
  bool reject0;
  bit<8> tenants;
  bit<8> tenants_var0;
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
  action lkp_cp_dict_tenants(bit<8> tenants)
    {
    hydra_metadata.tenants = tenants;
  }
  table tbl_lkp_cp_dict_tenants
    {
    key = {
      hydra_metadata.tenants_var0: exact;
    }
    actions = {
      lkp_cp_dict_tenants;
    }
    size = 64;
  }
  apply
    {
    hydra_header.eth_type.setValid();
    hydra_header.eth_type.value = ETHERTYPE_CHECKER;
    hydra_header.variables.setValid();
    hydra_metadata.tenants_var0 = standard_metadata.ingress_port;
    tbl_lkp_cp_dict_tenants.apply();
    hydra_header.variables.tenant = hydra_metadata.tenants;
  }
}
control telemetryControl(inout hydra_header_t hydra_header,
                         inout hydra_metadata_t hydra_metadata) {
  apply { 
  }
}
control checkerControl(inout hydra_header_t hydra_header,
                       inout hydra_metadata_t hydra_metadata) {
  action lkp_cp_dict_tenants(bit<8> tenants)
    {
    hydra_metadata.tenants = tenants;
  }
  table tbl_lkp_cp_dict_tenants
    {
    key = {
      hydra_metadata.tenants_var0: exact;
    }
    actions = {
      lkp_cp_dict_tenants;
    }
    size = 64;
  }
  apply
    {
    hydra_metadata.tenants_var0 = standard_metadata.egress_port;
    tbl_lkp_cp_dict_tenants.apply();
    if (hydra_header.variables.tenant!=hydra_metadata.tenants)
      {
      hydra_metadata.reject0 = true;
    }
    hydra_header.eth_type.setInvalid();
    hydra_header.variables.setInvalid();
  }
}

