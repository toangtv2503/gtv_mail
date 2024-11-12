class Attachment {
  String? url;
  String? fileName;
  String? extension;
  int? size;

  Attachment(this.url, this.fileName, this.extension, this.size);

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'fileName': fileName,
      'extension': extension,
      'size': size,
    };
  }

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      json['url'],
      json['fileName'],
      json['extension'],
      json['size'],
    );
  }
}
