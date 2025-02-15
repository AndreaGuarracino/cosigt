rule pansnspec_target:
    '''
    https://github.com/davidebolo1993/cosigt
    '''
    input:
        ref=config['reference']
    output:
        config['output'] + '/wfmash/target.fa'
    threads:
        1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * config['default']['mem_mb'],
        time=lambda wildcards, attempt: attempt * config['default']['time']
    container:
        'docker://davidebolo1993/samtools:1.21'
    benchmark:
        'benchmarks/pansnspec_toref.benchmark.txt'
    conda:
        '../envs/samtools.yaml'
    params:
        path=config['path']
    shell:
        '''
        samtools faidx \
        {input.ref} \
        $(echo {params.path} | cut -d "#" -f 2) | \
        sed "1 s/^.*$/>{params.path}/" \
        > {output}
        '''

rule add_target_to_queries:
    '''
    https://github.com/davidebolo1993/cosigt
    '''
    input:
        queries_fasta=config['assemblies'],
        target_fasta=rules.pansnspec_target.output
    output:
         config['output'] + '/wfmash/queries.fa'
    threads:
        1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * config['default']['mem_mb'],
        time=lambda wildcards, attempt: attempt * config['default']['time']
    benchmark:
        'benchmarks/add_target_to_queries.benchmark.txt'
    shell:
        '''
        zcat --force {input.queries_fasta} {input.target_fasta} | \
        awk '/^>/{{f=!d[$1];d[$1]=1}}f' \
        > {output}
        '''

rule samtools_faidx_queries:
    '''
    https://github.com/davidebolo1993/cosigt
    '''
    input:
        rules.add_target_to_queries.output
    output:
        config['output'] + '/wfmash/queries.fa.fai'
    threads:
        1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * config['default']['mem_mb'],
        time=lambda wildcards, attempt: attempt * config['default']['time']
    container:
        'docker://davidebolo1993/samtools:1.21'
    conda:
        '../envs/samtools.yaml'
    benchmark:
        'benchmarks/samtools_faidx_queries.benchmark.txt'
    shell:
        '''
        samtools faidx {input}
        '''                  

rule samtools_faidx_target:
    '''
    https://github.com/davidebolo1993/cosigt
    '''
    input:
        rules.pansnspec_target.output
    output:
        config['output'] + '/wfmash/target.fa.fai'
    threads:
        1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * config['default']['mem_mb'],
        time=lambda wildcards, attempt: attempt * config['default']['time']
    container:
        'docker://davidebolo1993/samtools:1.21'
    conda:
        '../envs/samtools.yaml'
    benchmark:
        'benchmarks/samtools_faidx_target.benchmark.txt'
    shell:
        '''
        samtools faidx {input}
        '''

rule wfmash_align:
    '''
    https://github.com/waveygang/wfmash
    '''
    input:
        queries_fasta=rules.add_target_to_queries.output,
        queries_fai=rules.samtools_faidx_queries.output,
        target_fasta=rules.pansnspec_target.output,
        target_fai=rules.samtools_faidx_target.output
    output:
        config['output'] + '/wfmash/queries_to_target.paf'
    threads:
        config['wfmash']['threads']
    resources:
        mem_mb=lambda wildcards, attempt: attempt * config['wfmash']['mem_mb'],
        time=lambda wildcards, attempt: attempt * config['wfmash']['time']
    container:
        'docker://davidebolo1993/wfmash:0.14.0'
    conda:
        '../envs/wfmash.yaml'
    benchmark:
        'benchmarks/wfmash_align.benchmark.txt'
    params:
        flags=config['wfmash']['params'],
        tmpdir=config['wfmash']['tmpdir'] 
    shell:
        '''
        wfmash \
            {input.target_fasta} \
            {input.queries_fasta} \
            -X \
            -t {threads} \
            -B {params.tmpdir} \
            {params.flags} > {output}
        '''
