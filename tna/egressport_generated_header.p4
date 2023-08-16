header eth_type2_t {
  bit<16> value;
}
header variables_t {
  bool good;
  bit<7> _pad;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
}
struct hydra_metadata_t {
  bool allowed_ports;
  bool reject0;
  bit<16> switch_id;
  bit<16> allowed_ports_var0;
  bit<9> allowed_ports_var1;
}