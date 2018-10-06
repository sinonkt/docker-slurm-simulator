#!/usr/bin/env python3
from slurm_parser import slurm_conf_parser

if __name__ == '__main__':
    
    import argparse
        
    parser = argparse.ArgumentParser(description='process sdiag')
    
    parser.add_argument('-c', '--config', required=True, type=str,
        help="slurm.conf file location.")
    parser.add_argument('-p', '--parameter', required=True, type=str,
        help="Parameter to get value")
    
    args = parser.parse_args()
    val = slurm_conf_parser(args.config)[args.parameter.lower()]
    print(val)