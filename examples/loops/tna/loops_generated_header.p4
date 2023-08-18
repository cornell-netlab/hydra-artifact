#define ETHERTYPE_CHECKER 0x5678

header eth_type2_t {
  bit<16> value;
}
header variables_t {
  bool loop;
  bit<7> _pad;
}
header switches_preamble_t {
  bit<8> num_items_switches;
}
header switches_item_t {
  bit<16> value;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
  switches_preamble_t switches_preamble;
  switches_item_t[3] switches;
}
struct hydra_metadata_t {
  bool reject0;
  bit<8> num_list_items;
  bit<16> switch_id;
}