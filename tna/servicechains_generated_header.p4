header eth_type2_t {
  bit<16> value;
}
header variables_t {
  bit<16> s1_id;
  bit<16> s2_id;
  bool s1_visited;
  bool s1s2_visited;
  bit<6> _pad;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
}
struct hydra_metadata_t {
  bool reject0; 
  bit<16> switch_id;
}