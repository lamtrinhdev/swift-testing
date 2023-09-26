//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors
//

@testable @_spi(ExperimentalTestRunning) import Testing

@Suite("Tag/Tag List Tests", .tags("trait"))
struct TagListTests {
  @Test(".tags() factory method with one string")
  func tagListFactoryMethodWithOneString() throws {
    let trait = Tag.List.tags("hello")
    #expect((trait as Any) is Tag.List)
    #expect(trait.tags == ["hello"])
    #expect(trait.tags == [Tag(rawValue: "hello")])
  }

  @Test(".tags() factory method with two string")
  func tagListFactoryMethodWithTwoStrings() throws {
    let trait = Tag.List.tags("hello", "world")
    #expect((trait as Any) is Tag.List)
    #expect(trait.tags == ["hello", "world"])
    #expect(trait.tags == [Tag(rawValue: "hello"), Tag(rawValue: "world")])
  }

  @Test(".tags() factory method with a collection of strings")
  func tagListFactoryMethodWithCollectionOfStrings() throws {
    let trait = Tag.List.tags(["hello", "world"])
    #expect((trait as Any) is Tag.List)
    #expect(trait.tags == ["hello", "world"])
    #expect(trait.tags == [Tag(rawValue: "hello"), Tag(rawValue: "world")])
  }

  @Test(".tags() factory method with strings and colors")
  func tagListFactoryMethodWithStringsAndColors() throws {
    let trait = Tag.List.tags("hello", "world", .red, .orange, .yellow, .green, .blue, .purple)
    #expect((trait as Any) is Tag.List)
    #expect(trait.tags == ["hello", "world", "red", "orange", "yellow", "green", "blue", "purple"])
    #expect(trait.tags == ["hello", "world", .red, .orange, .yellow, .green, .blue, .purple])
    #expect(trait.tags == [Tag(rawValue: "hello"), Tag(rawValue: "world"), Tag(rawValue: "red"), Tag(rawValue: "orange"), Tag(rawValue: "yellow"), Tag(rawValue: "green"), Tag(rawValue: "blue"), Tag(rawValue: "purple")])
    #expect(trait.tags == [Tag(rawValue: "hello"), Tag(rawValue: "world"), .red, .orange, .yellow, .green, .blue, .purple])
  }

  @Test("Tag.List.description property")
  func tagListDescription() throws {
    var trait = Tag.List.tags("hello", "world", .red, .orange, .yellow, .green, .blue, .purple)
    var tagWithCustomSourceCode = Tag(rawValue: "Tag Value")
    tagWithCustomSourceCode.sourceCode = SourceCode("Source.code.value")
    trait.tags.append(tagWithCustomSourceCode)
    #expect((trait as Any) is Tag.List)
    for tag in trait.tags {
      #expect(String(describing: tag) == tag.rawValue)
    }
    #expect(String(describing: trait) == "\"hello\", \"world\", .red, .orange, .yellow, .green, .blue, .purple, Source.code.value")
  }

  @Test("Tag.List comparisons",
    arguments: [(Tag.red, Tag("A")), (.red, .orange), (.red, .purple), ("A", "B"), ("A", "Z")]
  )
  func tagListComparison(lhs: Tag, rhs: Tag) throws {
    #expect(lhs != rhs)
    #expect(lhs < rhs)
    #expect(rhs > lhs)
    #expect(!(rhs < lhs))
  }

  @Test("Test.tags property")
  func testTagsProperty() {
    let test = Test(.tags("A", "B")) {}
    #expect(test.tags == ["A", "B"])
  }

  @Test("Tags are recursively applied")
  func tagsAreRecursivelyApplied() async throws {
    let plan = await Runner.Plan(selecting: TagTests.self)

    let typeTest = try #require(plan.steps.map(\.test).first { $0.name == "TagTests" })
    #expect(typeTest.tags == ["FromType"])
    let functionTest = try #require(plan.steps.map(\.test).first { $0.name == "test()" })
    #expect(functionTest.tags == ["FromFunction", "FromType"])
  }

  @Test("Tag source code is captured")
  func sourceCodeCaptured() async throws {
    let plan = await Runner.Plan(selecting: TagTests.self)
    let tagSourceCode = plan.steps.flatMap(\.test.tags).compactMap(\.sourceCode)
    #expect(tagSourceCode.contains { String(describing: $0) == ".namedConstant" })
    #expect(tagSourceCode.contains { String(describing: $0) == "Tag.functionCall(\"abc\")" })
  }
}

// MARK: - Fixtures

extension Tag {
  static var namedConstant: Tag { "Some Named Constant" }
  static func functionCall(_ string: String) -> Tag {
    Tag(rawValue: "String \(string)")
  }
}

func someTags() -> some Sequence<Tag> {
  ["FromFunctionCall1", "FromFunctionCall2"]
}

@Suite(.hidden, .tags("FromType"))
struct TagTests {
  @Test(.hidden, .tags("FromFunction"))
  func test() async throws {}

  @Test(
    .hidden,
    Tag.List.tags("FromFunctionPartiallyQualified"),
    Testing.Tag.List.tags("FromFunctionFullyQualified"),
    .tags(["FromFunctionArray1", "FromFunctionArray2"]),
    .tags(.namedConstant, Tag.functionCall("abc")),
    .tags(["FromConcatArray1.1", "FromConcatArray1.2"] as [Tag] + ["FromConcatArray2.1"] as [Tag]),
    .tags(someTags())
  )
  func variations() async throws {}
}
