/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;
const bit<16> TYPE_SRCROUTING = 0x1234;
const bit<16> TYPE_HYDRA = 0x5678;


#define MAX_HOPS 9

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header srcRoute_t {
    bit<1>    bos;
    bit<15>   port;
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

#include "hydra/source_route_generated.p4"


struct metadata {
    bool first_hop;
    bool last_hop; 
    hydra_metadata_t hydra_metadata;
}

struct headers {
    ethernet_t              ethernet;
    hydra_header_t          hydra_header;
    srcRoute_t[MAX_HOPS]    srcRoutes;
    ipv4_t                  ipv4;
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
        transition parse_hydra_or_eth_type;
    }

    state parse_hydra_or_eth_type {
        transition select(packet.lookahead<bit<16>>()) {
            TYPE_HYDRA: parse_hydra_headers;
            default: parse_srcRouting_first;
        }
    }

    state parse_hydra_headers {
        hydra_parser.apply(packet, hdr.hydra_header, meta.hydra_metadata);
        transition parse_srcRouting_first;
    }

    state parse_srcRouting_first {
        transition select(hdr.ethernet.etherType) {
            TYPE_SRCROUTING: parse_srcRouting;
            default: accept;
        }
    }

    state parse_srcRouting {
        packet.extract(hdr.srcRoutes.next);
        transition select(hdr.srcRoutes.last.bos) {
            1: parse_ipv4;
            default: parse_srcRouting;
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

    action srcRoute_nhop() {
        standard_metadata.egress_spec = (bit<9>)hdr.srcRoutes[0].port;
        hdr.srcRoutes.pop_front(1);
    }

    action srcRoute_finish() {
        hdr.ethernet.etherType = TYPE_IPV4;
    }

    action update_ttl(){
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
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
            initControl.apply(hdr.ipv4, hdr.hydra_header, meta.hydra_metadata);
        }

        if (hdr.srcRoutes[0].isValid()){
            if (hdr.srcRoutes[0].bos == 1){
                srcRoute_finish();
            }
            srcRoute_nhop();
            if (hdr.ipv4.isValid()){
                update_ttl();
            }
        }else{
            drop();
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
    apply {  }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {

    CheckerHeaderDeparser() hydra_deparser;

    apply {
        packet.emit(hdr.ethernet);
        hydra_deparser.apply(packet, hdr.hydra_header);
        packet.emit(hdr.srcRoutes);
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
