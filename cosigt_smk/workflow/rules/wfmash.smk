rule pansnspec_toref:
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
        'docker://davidebolo1993/cosigt_workflow:latest'
    benchmark:
        'benchmarks/pansnspec_toref.benchmark.txt'
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

rule wfmash_align:
    '''
    https://github.com/waveygang/wfmash
    '''
    input:
        queries=config['assemblies'],
        target=rules.pansnspec_toref.output
    output:
        config['output'] + '/wfmash/queries_to_target.paf'
    threads:
        config['wfmash']['threads']
    resources:
        mem_mb=lambda wildcards, attempt: attempt * config['wfmash']['mem_mb'],
        time=lambda wildcards, attempt: attempt * config['wfmash']['time']
    container:
        'docker://davidebolo1993/cosigt_workflow:latest'
    benchmark:
        'benchmarks/wfmash_align.benchmark.txt'
    params:
        flags=config['wfmash']['params'],
        tmpdir=config['wfmash']['tmpdir'] 
    shell:
        '''
        wfmash \
            {input.target} \
            {input.queries} \
            -X \
            -t {threads} \
            -B {params.tmpdir} \
            {params.flags}
        '''
