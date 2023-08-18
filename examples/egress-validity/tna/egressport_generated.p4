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
    hydra_header.variables.good = false;
    hydra_header.variables.good = true;
  }
}
control telemetryControl(inout hydra_header_t hydra_header,
                         inout hydra_metadata_t hydra_metadata,
                         in bit<9> egress_port) {
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
  action lkp_cp_dict_allowed_ports(bool allowed_ports)
    {
    hydra_metadata.allowed_ports = allowed_ports;
  }
  table tb_lkp_cp_dict_allowed_ports
    {
    key =
      {
      hydra_metadata.allowed_ports_var0: exact;
      hydra_metadata.allowed_ports_var1: exact;
    }
    actions = {
      lkp_cp_dict_allowed_ports;
    }
    size = 64;
  }
  apply
    {
    tb_init_cp_vars.apply();
    hydra_metadata.allowed_ports_var0 = hydra_metadata.switch_id;
    hydra_metadata.allowed_ports_var1 = egress_port;
    tb_lkp_cp_dict_allowed_ports.apply();
    if (hydra_metadata.allowed_ports) {
      hydra_header.variables.good = false;
    }
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
      
    }
    actions = {
      init_cp_vars;
    }
    size = 2;
  }
  apply
    {
    tb_init_cp_vars.apply();
    if (!hydra_header.variables.good) {
      hydra_metadata.reject0 = true;
    }
    hydra_header.eth_type.setInvalid();
    hydra_header.variables.setInvalid();
  }
}