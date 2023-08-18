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
control initControl(in lookup_metadata_t lkp_md,
                    inout hydra_header_t hydra_header,
                    inout hydra_metadata_t hydra_metadata) {
  action lkp_cp_dict_filtering_actions(bit<8> filtering_actions)
    {
    hydra_header.variables.filtering_action = filtering_actions;
  }
  table tb_lkp_cp_dict_filtering_actions
    {
    key = {
      hydra_header.variables.ue_ipv4_addr: exact;
      hydra_header.variables.app_ip_proto: exact;
      hydra_header.variables.app_ipv4_addr: exact;
      hydra_header.variables.app_l4_port: exact;
    }
    actions = {
      lkp_cp_dict_filtering_actions;
    }
    size = 64;
  }
  apply
    {
    hydra_header.eth_type.setValid();
    hydra_header.eth_type.value = ETHERTYPE_CHECKER;
    hydra_header.variables.setValid();
    hydra_header.variables.ue_ipv4_addr = 0;
    hydra_header.variables.app_ip_proto = 0;
    hydra_header.variables.app_ipv4_addr = 0;
    hydra_header.variables.app_l4_port = 0;
    hydra_header.variables.filtering_action = 0;
    hydra_header.variables.generate_report = 0;
    hydra_header.variables.is_report = 0;
    if (lkp_md.is_inner_ipv4) {
      hydra_header.variables.ue_ipv4_addr = lkp_md.ipv4_src;
      hydra_header.variables.app_ip_proto = lkp_md.ip_proto;
      hydra_header.variables.app_ipv4_addr = lkp_md.ipv4_dst;
      hydra_header.variables.app_l4_port = lkp_md.l4_dport;
    } else if (lkp_md.is_ipv4) {
      hydra_header.variables.ue_ipv4_addr = lkp_md.ipv4_dst;
      hydra_header.variables.app_ip_proto = lkp_md.ip_proto;
      hydra_header.variables.app_ipv4_addr = lkp_md.ipv4_src;
      hydra_header.variables.app_l4_port = lkp_md.l4_sport;
    }
    tb_lkp_cp_dict_filtering_actions.apply();
  }
}
control telemetryControl(inout hydra_header_t hydra_header,
                         inout hydra_metadata_t hydra_metadata) {
  apply { 
  }
}
control checkerControl(inout hydra_header_t hydra_header,
                       inout hydra_metadata_t hydra_metadata,
                       in bit<3> drop_ctl) {
  apply
    {
    if (hydra_header.variables.generate_report == 1) {
      hydra_header.variables.generate_report = 0;
      hydra_header.variables.is_report = 1;
      return;
    }
    if
      (hydra_header.variables.filtering_action==1 && drop_ctl!=1)
      {
      hydra_metadata.reject0 = true;
      hydra_header.variables.generate_report = 1;
      hydra_metadata.mirror_session_id = 123;
    }
    if
      (hydra_header.variables.filtering_action==2 && drop_ctl==1)
      { 
        hydra_header.variables.generate_report = 1;
        hydra_metadata.mirror_session_id = 123;
    }
    if (hydra_header.variables.generate_report != 1) {
      hydra_header.eth_type.setInvalid();
      hydra_header.variables.setInvalid();
    }
  }
}