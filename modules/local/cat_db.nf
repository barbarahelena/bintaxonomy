process CAT_DB {
    tag "${database.baseName}"

    conda "conda-forge::sed=4.7"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"

    input:
    path(database)

    output:
    tuple val("${database.toString()}"), path("database/*"), path("taxonomy/*"), emit: db
    path "versions.yml"                                                        , emit: versions

    script:
    """
    

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tar: \$(tar --version 2>&1 | sed -n 1p | sed 's/tar (GNU tar) //')
    END_VERSIONS
    """
}
