// Copyright 2020-present Open Networking Foundation
// SPDX-License-Identifier: Apache-2.0

#include <core.p4>
#include <tna.p4>

#include "shared/define.p4"
#include "shared/size.p4"
#include "shared/header.p4"
#include "tna/include/parser.p4"
#include "tna/include/control/packetio.p4"
#include "tna/include/control/filtering.p4"
#include "tna/include/control/forwarding.p4"
#include "tna/include/control/pre_next.p4"
#include "tna/include/control/lookup_md_init.p4"
#include "tna/include/control/acl.p4"
#include "tna/include/control/next.p4"
#include "tna/include/control/hasher.p4"
#include "tna/include/control/stats.p4"
#include "tna/include/control/slicing.p4"
#ifdef WITH_UPF
#include "tna/include/control/upf.p4"
#endif // WITH_UPF
#ifdef WITH_INT
#include "tna/include/control/int.p4"
#endif

control FabricIngress (
    /* Fabric.p4 */
    inout ingress_headers_t hdr,
    inout fabric_ingress_metadata_t fabric_md,
    /* TNA */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md) {

    LookupMdInit() lkp_md_init;
    StatsIngress() stats;
    PacketIoIngress() pkt_io;
    Filtering() filtering;
    Forwarding() forwarding;
    PreNext() pre_next;
    Acl() acl;
    Next() next;
    Hasher() hasher;
    IngressSliceTcClassifier() slice_tc_classifier;
    IngressQos() qos;
#ifdef WITH_UPF
    UpfIngress() upf;
#endif // WITH_UPF
#ifdef WITH_INT
    IntWatchlist() int_watchlist;
    IntIngress() int_ingress;
#endif // WITH_INT

    action set_first_hop() {
        fabric_md.first_hop = true;
    }

    table tb_check_first_hop {
        key = {
            ig_intr_md.ingress_port: exact;
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
        if (fabric_md.first_hop) {
            // Generic
            initControl.apply(hdr.hydra_header, fabric_md.hydra_metadata);
            // Multi-tenancy
            // initControl.apply(hdr.hydra_header, fabric_md.hydra_metadata, ig_intr_md.ingress_port);
            // Source routing
            // initControl.apply(hdr.ipv4, hdr.hydra_header, fabric_md.hydra_metadata);
            // Stateful firewall
            // initControl.apply(hdr, hdr.hydra_header, fabric_md.hydra_metadata);
        }
        
        lkp_md_init.apply(hdr, fabric_md.lkp);
        if (fabric_md.first_hop) {
            // App filtering
            // initControl.apply(fabric_md.lkp, hdr.hydra_header, fabric_md.hydra_metadata);
        }
        pkt_io.apply(hdr, fabric_md, ig_intr_md, ig_tm_md, ig_dprsr_md);
#ifdef WITH_INT
        int_watchlist.apply(hdr, fabric_md, ig_intr_md, ig_dprsr_md, ig_tm_md);
#endif // WITH_INT
        stats.apply(fabric_md.lkp, (FabricPortId_t)ig_intr_md.ingress_port, fabric_md.bridged.base.stats_flow_id);
        slice_tc_classifier.apply(hdr, ig_intr_md, fabric_md);
        filtering.apply(hdr, fabric_md, ig_intr_md);
#ifdef WITH_UPF
        if (!fabric_md.skip_forwarding) {
            upf.apply(hdr, fabric_md, ig_intr_md, ig_tm_md, ig_dprsr_md);
        }
#endif // WITH_UPF
        if (!fabric_md.skip_forwarding) {
            forwarding.apply(hdr, fabric_md, ig_dprsr_md);
        }
        hasher.apply(hdr, fabric_md);
        if (!fabric_md.skip_next) {
            pre_next.apply(hdr, fabric_md);
        }
        acl.apply(hdr, fabric_md, ig_intr_md, ig_dprsr_md, ig_tm_md);
        if (!fabric_md.skip_next) {
            next.apply(hdr, fabric_md, ig_intr_md, ig_tm_md);
        }
        qos.apply(fabric_md, ig_dprsr_md, ig_tm_md);
#ifdef WITH_INT
        // Should always apply last to guarantee generation of drop reports.
        int_ingress.apply(hdr, fabric_md, ig_intr_md, ig_dprsr_md, ig_tm_md);
#endif // WITH_INT
    }
}

control FabricEgress (
    /* Fabric.p4 */
    inout egress_headers_t hdr,
    inout fabric_egress_metadata_t fabric_md,
    /* TNA */
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md) {

    StatsEgress() stats;
    PacketIoEgress() pkt_io_egress;
    EgressNextControl() egress_next;
    EgressDscpRewriter() dscp_rewriter;
#ifdef WITH_UPF
    UpfEgress() upf;
#endif // WITH_UPF
#ifdef WITH_INT
    IntEgress() int_egress;
#endif // WITH_INT

    action set_last_hop() {
        fabric_md.last_hop = true;
    }

    table tb_check_last_hop {
        key = {
            eg_intr_md.egress_port: exact;
        }
        actions = {
            @defaultonly NoAction;
            set_last_hop;
        }
        const default_action = NoAction();
        size = 512;
    }

    apply {
        pkt_io_egress.apply(hdr, fabric_md, eg_intr_md);
        stats.apply(fabric_md.bridged.base.stats_flow_id, (FabricPortId_t)eg_intr_md.egress_port, fabric_md.bridged.bmd_type);
        egress_next.apply(hdr, fabric_md, eg_intr_md, eg_dprsr_md);
#ifdef WITH_UPF
        upf.apply(hdr, fabric_md);
#endif // WITH_UPF
#ifdef WITH_INT
        int_egress.apply(hdr, fabric_md, eg_intr_md, eg_prsr_md, eg_dprsr_md);
#endif
        dscp_rewriter.apply(fabric_md, eg_intr_md, hdr);

        // Generic
        // telemetryControl.apply(hdr.hydra_header, fabric_md.hydra_metadata);
        // Load balancing
        telemetryControl.apply(hdr.hydra_header, fabric_md.hydra_metadata, eg_intr_md.egress_port, eg_intr_md.pkt_length);
        // Egress port validity
        // telemetryControl.apply(hdr.hydra_header, fabric_md.hydra_metadata, eg_intr_md.egress_port);
        // Stateful firewall
        // telemetryControl.apply(hdr, hdr.hydra_header, fabric_md.hydra_metadata);
        tb_check_last_hop.apply();
        if (fabric_md.last_hop) {
            // Generic
            checkerControl.apply(hdr.hydra_header, fabric_md.hydra_metadata);
            // Multi-tenancy
            // checkerControl.apply(hdr.hydra_header, fabric_md.hydra_metadata, eg_intr_md.egress_port);
            // App filtering
            // checkerControl.apply(hdr.hydra_header, fabric_md.hydra_metadata, eg_dprsr_md.drop_ctl);
        }
        if (fabric_md.hydra_metadata.reject0) {
            eg_dprsr_md.drop_ctl = 1;
        } 
    }
}

Pipeline(
    FabricIngressParser(),
    FabricIngress(),
    FabricIngressDeparser(),
    FabricEgressParser(),
    FabricEgress(),
    FabricEgressDeparser()
) pipe;

Switch(pipe) main;
