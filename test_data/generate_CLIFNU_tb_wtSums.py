#!/usr/bin/env python
import csv
import random
import numpy as np

DATA_WIDTH_FRAC = 32

def prepend_tuple(rows, tup):
    new_rows = []
    for row in rows:
        new_rows.append(np.concatenate((tup, row)).astype(np.int))
    return new_rows

def with_periods(periods, weights, max_len=0):
    wts = []
    for i in range(len(periods)):
        for i in range(periods[i]-1):
            wts.append(0)
        wts.append(weights[i])
    assert len(wts) == sum(periods)

    if max_len != 0:
        wts = wts[:max_len]
    return np.array(wts)

############ Input Sequences ############

def periodic_simul():
    ex_wt_sum = 23 << DATA_WIDTH_FRAC
    in_wt_sum = ex_wt_sum/2

    rows = []
    for i in range(100):
        if i % 5 == 0:
            rows.append((ex_wt_sum, in_wt_sum))
        else:
            rows.append((0, 0))
    return np.array(rows)

def periodic_alternating():
    ex_wt_sum = 23 << DATA_WIDTH_FRAC
    in_wt_sum = ex_wt_sum/2

    rows = []
    for i in range(100):
        if i % 5 == 0:
            rows.append((ex_wt_sum, 0))
        elif i % 5 == 2:
            rows.append((0, in_wt_sum))
        else:
            rows.append((0, 0))
    return rows

def random_val_ex_in():
    ex_max_val = 23 << DATA_WIDTH_FRAC
    in_max_val = ex_max_val/2
    random.seed(1000)
    rows = []
    for i in range(1000):
        rows.append((random.randint(0,ex_max_val), random.randint(0,in_max_val)))
    return rows

def _combine_in_ex(wts_ex, wts_in):
    data_len = min(len(wts_ex), len(wts_in))
    return np.column_stack((wts_ex[:data_len], wts_in[:data_len]))

def _single_const_freq(length, wt, period):
    wt_repeated = np.repeat(wt, length)
    period_repeated = np.repeat(period, length)
    return with_periods(period_repeated, wt_repeated)

def single_constant_freq_ex_in():
    length = 100
    wts_ex = _single_const_freq(length, 23 << DATA_WIDTH_FRAC, 3)
    wts_in = _single_const_freq(length, 23 << DATA_WIDTH_FRAC, 6)
    return _combine_in_ex(wts_ex, wts_in)

def _single_rand_freq(min_length, wt, min_period, max_period):
    wt_repeated = np.repeat(wt, min_length)
    periods = np.random.randint(max(1,min_period), max_period, min_length)
    return with_periods(periods, wt_repeated)

def single_random_freq_ex_in():
    min_length = 100
    np.random.seed(1000)
    wts_ex = _single_rand_freq(min_length, 23 << DATA_WIDTH_FRAC, 1, 30)
    wts_in = _single_rand_freq(min_length, 23 << DATA_WIDTH_FRAC, 1, 30)
    return _combine_in_ex(wts_ex, wts_in)

def _many_const_freq(min_length, num, min_wt, max_wt, min_period, max_period):
    wts = []
    for i in range(num):
        wt = np.random.randint(min_wt, max_wt)
        period = np.random.randint(min_period, max_period)
        wts.append(_single_const_freq(min_length, wt, period))
    data_len = min([len(wt) for wt in wts])
    wts_np = np.ndarray((num, data_len))
    for i in range(num):
        wts_np[i,:] = wts[i][:data_len]
    wt_sums = np.sum(wts_np, axis=0)
    return wt_sums

def many_constant_freq_ex_in():
    min_length = 200
    num_ex_inputs = 5
    num_in_inputs = 5
    min_wt = 5 << DATA_WIDTH_FRAC
    max_wt = 23 << DATA_WIDTH_FRAC
    min_period = 1
    max_period = 30
    np.random.seed(861258011)

    wt_sums_ex = _many_const_freq(min_length, num_ex_inputs, min_wt, max_wt, min_period, max_period)
    wt_sums_in = _many_const_freq(min_length, num_ex_inputs, min_wt, max_wt, min_period, max_period)
    return _combine_in_ex(wt_sums_ex, wt_sums_in)

def _many_random_freq(min_length, num, min_wt, max_wt, min_period, max_period):
    wts = []
    for i in range(num):
        wt = np.random.randint(min_wt, max_wt)
        wts.append(_single_rand_freq(min_length, wt, min_period, max_period))
    data_len = min([len(wt) for wt in wts])
    wts_np = np.ndarray((num, data_len))
    for i in range(num):
        wts_np[i,:] = wts[i][:data_len]
    wt_sums = np.sum(wts_np, axis=0)
    return wt_sums

def many_random_freq_ex_in():
    min_length = 400
    num_ex_inputs = 5
    num_in_inputs = 5
    min_wt = 5 << DATA_WIDTH_FRAC
    max_wt = 23 << DATA_WIDTH_FRAC
    min_period = 1
    max_period = 30
    np.random.seed(8138013)

    wt_sums_ex = _many_const_freq(min_length, num_ex_inputs, min_wt, max_wt, min_period, max_period)
    wt_sums_in = _many_const_freq(min_length, num_ex_inputs, min_wt, max_wt, min_period, max_period)
    return _combine_in_ex(wt_sums_ex, wt_sums_in)

############ Main ############
vary_taumem = False

sets = []
if vary_taumem:
    # change to change which sequence to use
    # sequence = periodic_simul()
    # sequence = periodic_alternating()
    # sequence = random_val_ex_in()
    # sequence = single_constant_freq_ex_in(),
    # sequence = single_random_freq_ex_in(),
    # sequence = many_constant_freq_ex_in(),
    sequence = many_random_freq_ex_in()

    taumem_range = range(10, 500, 2)
    taugex_range = [max(1, taumem/100) for taumem in taumem_range]
    taugin_range = [taugex*2 for taugex in taugex_range]

    assert len(taumem_range) == len(taugex_range) and len(taumem_range) == len(taugin_range)

    for i in range(len(taumem_range)):
        rows = prepend_tuple(sequence, (taumem_range[i], taugex_range[i], taugin_range[i]))
        sets.append(rows)
    
else:
    default_taumem = 100
    default_taugex = 1
    default_taugin = 2

    sets = [
        # periodic_simul(),
        # periodic_alternating(),
        # single_constant_freq_ex_in(),
        single_random_freq_ex_in(),
        # many_constant_freq_ex_in(),
        # many_random_freq_ex_in(),
        # random_val_ex_in(),
    ]

    for i in range(len(sets)):
        sets[i] = prepend_tuple(sets[i], (default_taumem, default_taugex, default_taugin))

# add set index to front of each row
all_rows = []
for set_num in range(len(sets)):
    all_rows += prepend_tuple(sets[set_num], (set_num,))

with open("CLIFNU_tb_wtSums.csv", "w") as f:
    csv.writer(f).writerows(all_rows)