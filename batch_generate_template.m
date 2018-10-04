% batch to generate template

%% Generate template
run scatlas_create_mask.m
% scatlas_create_labels.m
run scatlas_transform_to_common_space.m
run scatlas_linear_bias_correction.m
run scatlas_apply_correction.m
run scatlas_generate_template.m
run scatlas_apply_warp.m
run scatlas_symmetrize_and_clean_template.m
run scatlas_concatenate_all_levels.m

%% Register external atlas to template
run scatlas_register_atlas_to_template.m