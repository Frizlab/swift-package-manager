//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_implementationOnly import SwiftASN1
@_implementationOnly import X509

// MARK: - SigningEntity is the entity that generated the signature

public enum SigningEntity: Hashable, Codable, CustomStringConvertible {
    case recognized(type: SigningEntityType, name: String?, organizationalUnit: String?, organization: String?)
    case unrecognized(name: String?, organizationalUnit: String?, organization: String?)

    static func from(certificate: Certificate) -> SigningEntity {
        let name = certificate.subject.commonName
        let organizationalUnit = certificate.subject.organizationalUnitName
        let organization = certificate.subject.organizationName

        if let type = certificate.signingEntityType {
            return .recognized(
                type: type,
                name: name,
                organizationalUnit: organizationalUnit,
                organization: organization
            )
        } else {
            return .unrecognized(
                name: name,
                organizationalUnit: organizationalUnit,
                organization: organization
            )
        }
    }

    public var description: String {
        switch self {
        case .recognized(let type, let name, let organizationalUnit, let organization):
            return "SigningEntity[type=\(type), name=\(String(describing: name)), organizationalUnit=\(String(describing: organizationalUnit)), organization=\(String(describing: organization))]"
        case .unrecognized(let name, let organizationalUnit, let organization):
            return "SigningEntity[name=\(String(describing: name)), organizationalUnit=\(String(describing: organizationalUnit)), organization=\(String(describing: organization))]"
        }
    }
}

// MARK: - SigningEntity types that SwiftPM recognizes

public enum SigningEntityType: String, Hashable, Codable {
    case adp // Apple Developer Program
}

extension ASN1ObjectIdentifier.NameAttributes {
    static let adpSwiftPackageMarker: ASN1ObjectIdentifier = [1, 2, 840, 113_635, 100, 6, 1, 35]
}

extension Certificate {
    var signingEntityType: SigningEntityType? {
        if self.hasExtension(oid: ASN1ObjectIdentifier.NameAttributes.adpSwiftPackageMarker),
           Certificates.wwdrIntermediates
           .first(where: { $0.subject == self.issuer && $0.publicKey.isValidSignature(self.signature, for: self) }) !=
           nil
        {
            return .adp
        }
        return .none
    }
}
