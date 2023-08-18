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
  action init_cp_vars(bit<8> left_port, bit<8> right_port, bit<16> thresh)
    {
    hydra_metadata.left_port = left_port;
    hydra_metadata.right_port = right_port;
    hydra_metadata.thresh = thresh;
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
    hydra_header.variables.balanced = false;
  }
}
control telemetryControl(inout hydra_header_t hydra_header,
                         inout hydra_metadata_t hydra_metadata,
                         in bit<9> eg_port,
                         in bit<16> packet_length) {
  bit<8> eg_port_temp;
  bit<16> diff;
  bit<16> greater;
  action init_cp_vars(bit<8> left_port, bit<8> right_port, bit<16> thresh)
    {
    hydra_metadata.left_port = left_port;
    hydra_metadata.right_port = right_port;
    hydra_metadata.thresh = thresh;
  }
  table tb_init_cp_vars {
    key = {
      
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
  table tb_lkp_cp_dict_is_uplink
    {
    key = {
      hydra_metadata.is_uplink_var0: exact;
    }
    actions = {
      lkp_cp_dict_is_uplink;
    }
    size = 64;
  }
  Register<bit<16>, bit<1>>(2, 0) left_load_sensor;
  RegisterAction<bit<16>, bit<1>, bit<16>>(left_load_sensor) increment_left_load = {
        void apply(inout bit<16> stored_load, out bit<16> result) {
            stored_load = stored_load + packet_length;
            result = stored_load;
        }
    };
  RegisterAction<bit<16>, bit<1>, bit<16>>(left_load_sensor) read_left_load = {
        void apply(inout bit<16> stored_load, out bit<16> result) {
            result = stored_load;
        }
    };
  Register<bit<16>, bit<1>>(2, 0) right_load_sensor;
  RegisterAction<bit<16>, bit<1>, bit<16>>(right_load_sensor) increment_right_load = {
        void apply(inout bit<16> stored_load, out bit<16> result) {
            stored_load = stored_load + packet_length;
            result = stored_load;
        }
    };
  RegisterAction<bit<16>, bit<1>, bit<16>>(right_load_sensor) read_right_load = {
        void apply(inout bit<16> stored_load, out bit<16> result) {
            result = stored_load;
        }
    };
  apply
    {
    eg_port_temp = (bit<8>) eg_port;
    tb_init_cp_vars.apply();
    hydra_metadata.is_uplink_var0 = (bit<8>) eg_port;
    tb_lkp_cp_dict_is_uplink.apply();
    if (hydra_metadata.is_uplink)
      {
      if (eg_port_temp==hydra_metadata.left_port)
        {
        hydra_metadata.left_load = increment_left_load.execute(0);
        hydra_metadata.right_load = read_right_load.execute(0);
      }else
      {
      if (eg_port_temp==hydra_metadata.right_port)
        {
        hydra_metadata.left_load = read_left_load.execute(0);
        hydra_metadata.right_load = increment_right_load.execute(0);
      }
      }
    }
    greater = max(hydra_metadata.left_load, hydra_metadata.right_load);
    if (greater == hydra_metadata.left_load) {
      diff = hydra_metadata.left_load - hydra_metadata.right_load;
    } else {
      diff = hydra_metadata.right_load - hydra_metadata.left_load;
    }
    greater = max(diff, hydra_metadata.thresh);
    if (greater == diff) {
      hydra_header.variables.balanced = false;
    }
  }
}
control checkerControl(inout hydra_header_t hydra_header,
                       inout hydra_metadata_t hydra_metadata) {
  bit<16> l_load;
  bit<16> r_load;
  bit<16> diff;
  bool r_greater;
  action init_cp_vars(bit<8> left_port, bit<8> right_port, bit<16> thresh)
    {
    hydra_metadata.left_port = left_port;
    hydra_metadata.right_port = right_port;
    hydra_metadata.thresh = thresh;
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
    if (!hydra_header.variables.balanced) {
      hydra_metadata.reject0 = true;
    }
    hydra_header.eth_type.setInvalid();
    hydra_header.variables.setInvalid();
  }
}