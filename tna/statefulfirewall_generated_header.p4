header eth_type2_t {
  bit<16> value;
}
header variables_t {
  bool violated;
  bit<7> _pad;
  bit<8> generate_report;
  bit<8> is_report;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
}
struct hydra_metadata_t {
  bool reject0;
  bool allowed;
  bool lasthop;
  bit<32> allowed_var0;
  bit<32> allowed_var1;
  MirrorId_t mirror_session_id;
}