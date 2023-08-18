#define ETHERTYPE_CHECKER 0x5678

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
                    inout hydra_metadata_t hydra_metadata,
                    in bit<9> in_port) {
  action lkp_cp_dict_tenants(bit<8> tenants)
    {
    hydra_metadata.tenants = tenants;
  }
  table tb_lkp_cp_dict_tenants
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
    hydra_header.variables.tenant = 0;

    hydra_metadata.tenants_var0 = (bit<8>) in_port;
    tb_lkp_cp_dict_tenants.apply();
    hydra_header.variables.tenant = hydra_metadata.tenants;
  }
}
control telemetryControl(inout hydra_header_t hydra_header,
                         inout hydra_metadata_t hydra_metadata) {
  apply { 
  }
}
control checkerControl(inout hydra_header_t hydra_header,
                       inout hydra_metadata_t hydra_metadata,
                       in bit<9> eg_port) {
  action lkp_cp_dict_tenants(bit<8> tenants)
    {
    hydra_metadata.tenants = tenants;
  }
  table tb_lkp_cp_dict_tenants
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
    hydra_metadata.tenants_var0 = (bit<8>) eg_port;
    tb_lkp_cp_dict_tenants.apply();
    if (hydra_header.variables.tenant!=hydra_metadata.tenants)
      {
      hydra_metadata.reject0 = true;
    }

    hydra_header.eth_type.setInvalid();
    hydra_header.variables.setInvalid();
  }
}