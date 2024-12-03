/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_bintaxonomy'

//
// MODULE: Local to the pipeline
//
include { CAT_DB                                              } from '../modules/local/cat_db'
include { CAT_DB_GENERATE                                     } from '../modules/local/cat_db_generate'
include { CAT                                                 } from '../modules/local/cat'
include { CAT_SUMMARY                                         } from "../modules/local/cat_summary"
include { KRAKEN2                                             } from "../modules/local/kraken2"
include { COMBINE_TSV as COMBINE_SUMMARY_TSV                  } from '../modules/local/combine_tsv'

////////////////////////////////////////////////////
/* --  Create channel for reference databases  -- */
////////////////////////////////////////////////////

if(params.cat_db){
    ch_cat_db_file = Channel
        .value(file( "${params.cat_db}" ))
} else {
    ch_cat_db_file = Channel.empty()
}

if(params.kraken_db){
    ch_kraken_db = Channel.value(file( "${params.kraken_db}"))
    ch_taxtable = Channel.value(file( "${params.taxtable}"))
} else {
    ch_kraken_db = Channel.empty()
    ch_taxtable = Channel.empty()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow BINTAXONOMY {

    take:
    ch_input_bins

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
    if(params.taxtool == 'cat'){
        /*
        * CAT: taxonomic classification of bins
        */
        ch_bins = ch_input_bins
                    .map { sample, name, bins -> [sample, bins]}
                    .groupTuple(by: 0)
        ch_cat_db = params.cat_db
        CAT (
            ch_bins,
            ch_cat_db
        )
        // Group all classification results for each sample in a single file
        ch_cat_summary = CAT.out.tax_classification_names
            .collectFile(keepHeader: true) {
                    meta, classification ->
                    ["${meta.id}.txt", classification]
            }
        // Group all classification results for the whole run in a single file
        CAT_SUMMARY(
            ch_cat_summary.collect()
        )
        ch_versions = ch_versions.mix(CAT.out.versions.first())
        ch_versions = ch_versions.mix(CAT_SUMMARY.out.versions)

        // If CAT is not run, then the CAT global summary should be an empty channel
        if ( params.cat_db_generate || params.cat_db) {
            ch_cat_global_summary = CAT_SUMMARY.out.combined
        } else {
            ch_cat_global_summary = Channel.empty()
        }
    }
    if(params.taxtool == 'kraken'){
        /*
        * KRAKEN: taxonomic classification of bins
        */
        ch_bins = ch_input_bins
                    .map { sample, name, bins -> [sample, bins]}
                    .groupTuple(by: 0)
        KRAKEN2 (
            ch_bins,
            ch_kraken_db,
            ch_taxtable
        )
        
        // Group all classification results for the whole run in a single file
        
        ch_versions = ch_versions.mix(KRAKEN2.out.versions.first())

        COMBINE_SUMMARY_TSV ( KRAKEN2.out.tax.map{it[1]}.collect() )
    }
    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_pipeline_software_mqc_versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/