process CAT {
    tag "${sample}"

    conda "bioconda::cat=6.0.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/cat:6.0.1--hdfd78af_0' :
        'biocontainers/cat:6.0.1--hdfd78af_0' }"

    input:
    tuple val(sample), path(bins)
    path(database)

    output:
    tuple val(sample), path("*.bin2classification.names.txt")    , emit: tax_classification_names
    path("*.ORF2LCA.names.txt.gz")                             , emit: orf2lca_classification
    path("raw/*.ORF2LCA.txt.gz")                               , emit: orf2lca
    path("raw/*.predicted_proteins.faa.gz")                    , emit: faa
    path("raw/*.predicted_proteins.gff.gz")                    , emit: gff
    path("raw/*.log")                                          , emit: log
    path("raw/*.bin2classification.txt.gz")                    , emit: tax_classification_taxids
    path "versions.yml"                                        , emit: versions

    script:
    def official_taxonomy = params.cat_official_taxonomy ? "--only_official" : ""
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${sample}"
    """
    mkdir bins
    mv ${bins} bins/

    mkdir temp

    CAT_pack bins $args \\
        -b "bins/" -d ${database}/database/ \\
        -t ${database}/taxonomy/ \\
        -n "${task.cpus}" \\
        --verbose \\
        --tmpdir temp/ \\
        -s .fa \\
        --top 6 \\
        -o "${prefix}" \\
        --I_know_what_Im_doing
    
    CAT_pack add_names \\
        -i "${prefix}.ORF2LCA.txt" \\
        -o "${prefix}.ORF2LCA.names.txt" \\
        -t taxonomy/ ${official_taxonomy}
    
    CAT_pack add_names \\
        -i "${prefix}.bin2classification.txt" \\
        -o "${prefix}.bin2classification.names.txt" \\
        -t taxonomy/ ${official_taxonomy}

    mkdir raw
    mv *.ORF2LCA.txt *.predicted_proteins.faa *.predicted_proteins.gff *.log *.bin2classification.txt raw/
    cp *.bin2classification.names.txt raw/
    gzip "raw/${prefix}.ORF2LCA.txt" \
        "raw/${prefix}.concatenated.predicted_proteins.faa" \
        "raw/${prefix}.concatenated.predicted_proteins.gff" \
        "raw/${prefix}.bin2classification.txt" \
        "${prefix}.ORF2LCA.names.txt" \
        "raw/${prefix}.bin2classification.names.txt"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        CAT: \$(CAT --version | sed "s/CAT v//; s/(.*//")
        diamond: \$(diamond --version 2>&1 | tail -n 1 | sed 's/^diamond version //')
    END_VERSIONS
    """
}
