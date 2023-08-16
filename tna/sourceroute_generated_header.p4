header eth_type2_t {
  bit<16> value;
}
header variables_t {
  bit<8> index;
  bool to_reject;
  bit<7> _pad;
}
header expected_path_preamble_t {
  bit<8> num_items_expected_path;
}
header expected_path_item_t {
  bit<16> value;
}
struct hydra_header_t {
  eth_type2_t eth_type;
  variables_t variables;
  expected_path_preamble_t expected_path_preamble;
  expected_path_item_t[3] expected_path;
}
struct hydra_metadata_t {
  bool reject0;
  bit<8> num_list_items;
  bit<16> switch_id;
  bit<32> expected_s3_dict_var0;
  bit<32> expected_s2_dict_var0;
  bit<32> expected_s1_dict_var0;
  bit<16> expected_s1_dict;
  bit<16> expected_s2_dict;
  bit<16> expected_s3_dict;
}