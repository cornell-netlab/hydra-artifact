#define ETHERTYPE_CHECKER 0x5678

parser CheckerHeaderParser(packet_in packet, out hydra_header_t hydra_header,
                           inout hydra_metadata_t hydra_metadata) {
  ParserCounter() slices_counter;
  state start {
    packet.extract(hydra_header.eth_type);
    transition parse_variables;
  }
  state parse_variables {
    packet.extract(hydra_header.variables);
    transition parse_slices_preamble;
  }
  state parse_slices_preamble
    {
    packet.extract(hydra_header.slices_preamble);
    slices_counter.set(hydra_header.slices_preamble.num_items_slices);
    transition select(slices_counter.is_zero()) {
      true: accept;
      default: parse_slices;
    }
  }
  state parse_slices
    {
    packet.extract(hydra_header.slices.next);
    slices_counter.decrement(1);
    transition select(slices_counter.is_zero()) {
      true: accept;
      default: parse_slices;
    }
  }
}
control CheckerHeaderDeparser(packet_out packet,
                              in hydra_header_t hydra_header) {
  apply
    {
    packet.emit(hydra_header.eth_type);
    packet.emit(hydra_header.variables);
    packet.emit(hydra_header.slices_preamble);
    packet.emit(hydra_header.slices);
  }
}
control initControl(inout hydra_header_t hydra_header,
                    inout hydra_metadata_t hydra_metadata) {
  action init_cp_vars(bit<32> switch_slice)
    {
    hydra_metadata.switch_slice = switch_slice;
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
    hydra_header.slices_preamble.setValid();
    hydra_header.slices_preamble.num_items_slices = 0;
  }
}
control telemetryControl(inout hydra_header_t hydra_header,
                         inout hydra_metadata_t hydra_metadata) {
  action init_cp_vars(bit<32> switch_slice)
    {
    hydra_metadata.switch_slice = switch_slice;
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
    hydra_header.slices.push_front(1);
    hydra_header.slices[0].setValid();
    hydra_header.slices[0].value = 1;
    hydra_header.slices_preamble.num_items_slices = hydra_header.slices_preamble.num_items_slices + 1;
  }
}
control checkerControl(inout hydra_header_t hydra_header,
                       inout hydra_metadata_t hydra_metadata) {
  action init_cp_vars(bit<32> switch_slice)
    {
    hydra_metadata.switch_slice = switch_slice;
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
    bit<32> prev_slice = hydra_header.slices[0].value;
    bit<32> slice;
    if (hydra_header.slices[0].isValid())
      {
      slice = hydra_header.slices[0].value;
      if (prev_slice!=slice) {
        hydra_metadata.reject0 = true;
      }
      prev_slice = slice;
      if (hydra_header.slices[1].isValid())
        {
        slice = hydra_header.slices[1].value;
        if (prev_slice!=slice) {
          hydra_metadata.reject0 = true;
        }
        prev_slice = slice;
        if (hydra_header.slices[2].isValid())
          {
          slice = hydra_header.slices[2].value;
          if (prev_slice!=slice) {
            hydra_metadata.reject0 = true;
          }
          prev_slice = slice;
        }
      }
    }

    hydra_header.eth_type.setInvalid();
    hydra_header.variables.setInvalid();
    hydra_header.slices_preamble.setInvalid();
    hydra_header.slices[0].setInvalid();
    hydra_header.slices[1].setInvalid();
    hydra_header.slices[2].setInvalid();
  }
}
