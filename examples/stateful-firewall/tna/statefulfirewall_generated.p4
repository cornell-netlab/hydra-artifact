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
control initControl(in ingress_headers_t hdr,
                    inout hydra_header_t hydra_header,
                    inout hydra_metadata_t hydra_metadata) {
  action init_cp_vars(bool lasthop) {
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
  action lkp_cp_dict_allowed(bool allowed) {
    hydra_metadata.allowed = allowed;
  }
  table tbl_lkp_cp_dict_allowed
    {
    key =
      {
      hydra_metadata.allowed_var0: exact;
      hydra_metadata.allowed_var1: exact;
    }
    actions = {
      lkp_cp_dict_allowed;
    }
    size = 64;
  }
  apply
    {
    tb_init_cp_vars.apply();
    hydra_header.eth_type.setValid();
    hydra_header.eth_type.value = ETHERTYPE_CHECKER;
    hydra_header.variables.setValid();
    hydra_header.variables.violated = false;
    hydra_metadata.allowed_var0 = hdr.ipv4.src_addr;
    hydra_metadata.allowed_var1 = hdr.ipv4.dst_addr;
    tbl_lkp_cp_dict_allowed.apply();
    if (!hydra_metadata.allowed) {
      hydra_header.variables.violated = true;
    }
  }
}
control telemetryControl(in egress_headers_t hdr,
                         inout hydra_header_t hydra_header,
                         inout hydra_metadata_t hydra_metadata) {
  action init_cp_vars(bool lasthop) {
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
  action lkp_cp_dict_allowed(bool allowed) {
    hydra_metadata.allowed = allowed;
  }
  table tbl_lkp_cp_dict_allowed
    {
    key =
      {
      hydra_metadata.allowed_var0: exact;
      hydra_metadata.allowed_var1: exact;
    }
    actions = {
      lkp_cp_dict_allowed;
    }
    size = 64;
  }
  apply
    {
    if (hydra_header.variables.generate_report == 1) {
      hydra_header.variables.generate_report = 0;
      hydra_header.variables.is_report = 1;
      return;
    }
    tb_init_cp_vars.apply();
    hydra_metadata.allowed_var0 = hdr.ipv4.dst_addr;
    hydra_metadata.allowed_var1 = hdr.ipv4.src_addr;
    tbl_lkp_cp_dict_allowed.apply();
    if (hydra_metadata.lasthop && !hydra_metadata.allowed)
      {
      hydra_header.variables.generate_report = 1;
      hydra_metadata.mirror_session_id = 123;
    }
  }
}
control checkerControl(inout hydra_header_t hydra_header,
                       inout hydra_metadata_t hydra_metadata) {
  action init_cp_vars(bool lasthop) {
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
    if (hydra_header.variables.violated) {
      hydra_metadata.reject0 = true;
    }
    if (hydra_header.variables.generate_report != 1) {
      hydra_header.eth_type.setInvalid();
      hydra_header.variables.setInvalid();
    }
  }
}