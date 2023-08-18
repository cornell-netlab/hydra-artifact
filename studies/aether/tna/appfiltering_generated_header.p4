header eth_type2_t {
  bit<16> value;
}
header variables_t {
  bit<32> ue_ipv4_addr;
  bit<32> app_ipv4_addr;
  bit<8> app_ip_proto;
  bit<16> app_l4_port;
  bit<8> filtering_action;
  bit<8>   generate_report;
  bit<8>   is_report;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
}
struct hydra_metadata_t {
  bit<32> filtering_actions_var0;
  bit<8> filtering_actions_var1;
  bit<32> filtering_actions_var2;
  bit<16> filtering_actions_var3;
  bit<8> filtering_actions;
  bool reject0;
  MirrorId_t mirror_session_id;
}