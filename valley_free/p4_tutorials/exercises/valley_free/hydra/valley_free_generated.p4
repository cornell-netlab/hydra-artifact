#include <v1model.p4> 

#define ETHERTYPE_CHECKER 0x5678;

header eth_type2_t {
  bit<16> value;
}
header variables_t {
  bool visited_spine;
  bool to_reject;
  bit<6> _pad;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
}
struct hydra_metadata_t {
  bool reject0;
  bool is_spine_switch;
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
  
  apply
    {
    hydra_header.eth_type.setValid();
    hydra_header.eth_type.value = ETHERTYPE_CHECKER;
    hydra_header.variables.setValid();
    hydra_header.variables.visited_spine = false;
    hydra_header.variables.to_reject = false;
  }
}
control telemetryControl(inout hydra_header_t hydra_header,
                         inout hydra_metadata_t hydra_metadata) {
  action init_cp_vars(bit<1> is_spine_switch)
    {
    hydra_metadata.is_spine_switch = (bool) is_spine_switch;
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
    if (hydra_metadata.is_spine_switch)
      {
      if (hydra_header.variables.visited_spine)
        {
        hydra_header.variables.to_reject = true;
      }
      hydra_header.variables.visited_spine = true;
    }
  }
}
control checkerControl(inout hydra_header_t hydra_header,
                       inout hydra_metadata_t hydra_metadata) {
  
  apply
    {
    if (hydra_header.variables.to_reject) {
      hydra_metadata.reject0 = true;
    }
    hydra_header.eth_type.setInvalid();
    hydra_header.variables.setInvalid();
  }
}

