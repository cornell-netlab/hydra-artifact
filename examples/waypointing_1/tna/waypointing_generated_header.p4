header eth_type2_t {
  bit<16> value;
}
header variables_t {
  
}
header paths_preamble_t {
  bit<8> num_items_paths;
}
header paths_item_t {
  bit<16> value;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
  paths_preamble_t paths_preamble;
  paths_item_t[3] paths;
}
struct hydra_metadata_t {
  bool reject0;
  bit<8> num_list_items;
  bit<16> switch_id;
}