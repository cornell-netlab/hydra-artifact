#define ETHERTYPE_CHECKER 0x5678

header eth_type2_t {
  bit<16> value;
}
header variables_t {
  bit<8> tenant;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
}
struct hydra_metadata_t {
  bit<8> tenants;
  bit<8> tenants_var0; 
  bool reject0;
}