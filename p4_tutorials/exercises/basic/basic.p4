/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>
#include "hydra/color_generated.p4"

const bit<16> TYPE_IPV4 = 0x800;
const bit<16> TYPE_HYDRA = 0x5678;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
}

header eth_type_t {
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

struct metadata {
    bool first_hop;
    bool last_hop;
    hydra_metadata_t hydra_metadata;
}

struct headers {
    ethernet_t   ethernet;
    hydra_header_t hydra_header;
    eth_type_t eth_type;
    ipv4_t       ipv4;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    CheckerHeaderParser() hydra_parser;

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition parse_tele_or_eth_type;
    }

    state parse_tele_or_eth_type {
        transition select(packet.lookahead<bit<16>>()) {
            TYPE_HYDRA: parse_hydra_headers;
            default: parse_eth_type;
        }
    }

    state parse_hydra_headers {
        hydra_parser.apply(packet, hdr.hydra_header, meta.hydra_metadata);
        transition parse_eth_type;
    }

    state parse_eth_type {
        packet.extract(hdr.eth_type);
        transition select(hdr.eth_type.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    action drop() {
        mark_to_drop(standard_metadata);
    }

    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = drop();
    }

    action set_first_hop() {
        meta.first_hop = true;
    }

    table tb_check_first_hop {
        key = {
            standard_metadata.ingress_port: exact;
        }
        actions = {
            @defaultonly NoAction;
            set_first_hop;
        }
        const default_action = NoAction();
        size = 512;
    }

    apply {
        tb_check_first_hop.apply();
        if (meta.first_hop) {
            initControl.apply(hdr.hydra_header, meta.hydra_metadata);
        }
        if (hdr.ipv4.isValid()) {
            ipv4_lpm.apply();
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {

    action set_last_hop() {
        meta.last_hop = true;
    }

    table tb_check_last_hop {
        key = {
            standard_metadata.egress_port: exact;
        }
        actions = {
            @defaultonly NoAction;
            set_last_hop;
        }
        const default_action = NoAction();
        size = 512;
    }

    apply {  
        telemetryControl.apply(hdr.hydra_header, meta.hydra_metadata);
        tb_check_last_hop.apply();
        if (meta.last_hop) {
            checkerControl.apply(hdr.hydra_header, meta.hydra_metadata);
        }
        if (meta.hydra_metadata.reject0) {
            mark_to_drop(standard_metadata);
        }
    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
     apply {
        update_checksum(
        hdr.ipv4.isValid(),
            { hdr.ipv4.version,
              hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {

    CheckerHeaderDeparser() hydra_deparser;

    apply {
        packet.emit(hdr.ethernet);
        hydra_deparser.apply(packet, hdr.hydra_header);
        packet.emit(hdr.eth_type);
        packet.emit(hdr.ipv4);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
