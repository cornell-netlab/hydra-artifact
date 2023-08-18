#define ETHERTYPE_CHECKER 0x5678

header eth_type2_t {
  bit<16> value;
}
header variables_t {
  
}
header slices_preamble_t {
  bit<8> num_items_slices;
}
header slices_item_t {
  bit<32> value;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
  slices_preamble_t slices_preamble;
  slices_item_t[3] slices;
}
struct hydra_metadata_t {
  bool reject0;
  bit<8> num_list_items;
  bit<32> switch_slice;
}
