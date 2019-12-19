#!/usr/bin/env python
import csv
import random

def write_rows(fname, rows):
    with open(fname, "w") as f:
        wr = csv.writer(f)
        for row in rows:
            wr.writerow(row)

def periodic_simul():
    ex_wt_sum = 100000000000
    in_wt_sum = int(0.5*ex_wt_sum)

    rows = []
    for i in range(100):
        if i % 5 == 0:
            rows.append((ex_wt_sum, in_wt_sum))
        else:
            rows.append((0, 0))
    write_rows("CLIFN_tb_wtSums_periodic_simul.csv", rows)

def periodic_alternating():
    ex_wt_sum = 100000000000
    in_wt_sum = int(0.5*ex_wt_sum)

    rows = []
    for i in range(100):
        if i % 5 == 0:
            rows.append((ex_wt_sum, 0))
        elif i % 5 == 2:
            rows.append((0, in_wt_sum))
        else:
            rows.append((0, 0))
    write_rows("CLIFN_tb_wtSums_periodic_alternating.csv", rows)

def random_both():
    ex_max_val = 100000000000
    in_max_val = ex_max_val/2
    random.seed(1000)
    rows = []
    for i in range(1000):
        rows.append((random.randint(0,ex_max_val), random.randint(0,in_max_val)))
    write_rows("CLIFN_tb_wtSums_random_both.csv", rows)

periodic_simul()
periodic_alternating()
random_both()