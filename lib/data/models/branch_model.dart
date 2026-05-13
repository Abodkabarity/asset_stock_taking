class BranchModel {
  final String branchName;

  BranchModel({required this.branchName});

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(branchName: json['branch_name']);
  }
}
