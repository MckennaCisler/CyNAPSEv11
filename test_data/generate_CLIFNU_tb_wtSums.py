#!/usr/bin/env python
import csv
import random

DATA_WIDTH_FRAC = 32

############ Input Sequences ############

def periodic_simul(taumem, taugex, taugin):
    ex_wt_sum = 23 << DATA_WIDTH_FRAC
    in_wt_sum = ex_wt_sum/2

    rows = []
    for i in range(100):
        if i % 5 == 0:
            rows.append((taumem, taugex, taugin, ex_wt_sum, in_wt_sum))
        else:
            rows.append((taumem, taugex, taugin, 0, 0))
    return rows

def periodic_alternating(taumem, taugex, taugin):
    ex_wt_sum = 23 << DATA_WIDTH_FRAC
    in_wt_sum = ex_wt_sum/2

    rows = []
    for i in range(100):
        if i % 5 == 0:
            rows.append((taumem, taugex, taugin, ex_wt_sum, 0))
        elif i % 5 == 2:
            rows.append((taumem, taugex, taugin, 0, in_wt_sum))
        else:
            rows.append((taumem, taugex, taugin, 0, 0))
    return rows

def random_both(taumem, taugex, taugin):
    ex_max_val = 23 << DATA_WIDTH_FRAC
    in_max_val = ex_max_val/2
    random.seed(1000)
    rows = []
    for i in range(1000):
        rows.append((taumem, taugex, taugin, random.randint(0,ex_max_val), random.randint(0,in_max_val)))
    return rows

############ Main ############
vary_taumem = True

sets = []
if vary_taumem:
    # change to change which sequence to use
    sequence_f = periodic_simul
    # sequence_f = periodic_alternating
    # sequence_f = random_both

    taumem_range = range(10, 500, 2)
    taugex_range = [max(1, taumem/100) for taumem in taumem_range]
    taugin_range = [taugex*2 for taugex in taugex_range]

    assert len(taumem_range) == len(taugex_range) and len(taumem_range) == len(taugin_range)

    for i in range(len(taumem_range)):
        sets.append(sequence_f(taumem_range[i], taugex_range[i], taugin_range[i]))
else:
    default_taumem = 100
    default_taugex = 1
    default_taugin = 2

    sets = [
        periodic_simul(default_taumem, default_taugex, default_taugin),
        periodic_alternating(default_taumem, default_taugex, default_taugin),
        random_both(default_taumem, default_taugex, default_taugin)
    ]

all_rows = []
for set_num in range(len(sets)):
    for row in sets[set_num]:
        all_rows.append((set_num,) + row)

with open("CLIFNU_tb_wtSums.csv", "w") as f:
    csv.writer(f).writerows(all_rows)