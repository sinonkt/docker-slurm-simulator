#!/usr/bin/env python3
from slurm_parser import slurm_conf_parser, print_updated_config_file

if __name__ == '__main__':
    
    import argparse
        
    parser = argparse.ArgumentParser(description='Overide user\'s provided slurm.conf for some default value')
    
    parser.add_argument('-c', '--config', required=True, type=str,
        help="slurm.conf file location.")
    parser.add_argument('-o', '--overide', required=True, type=str,
        help="default slurm.conf to overide some parameter.")
    
    args = parser.parse_args()
    print_updated_config_file(args.config, slurm_conf_parser(args.overide))