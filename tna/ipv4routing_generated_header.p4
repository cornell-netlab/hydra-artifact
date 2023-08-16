header eth_type2_t {
  bit<16> value;
}
header variables_t {
  bool to_reject;
  bit<7> _pad;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
}
struct hydra_metadata_t {
  bool firsthop;
  bool lasthop;
  bool is_switch_leaf; 
  bool reject0;
}