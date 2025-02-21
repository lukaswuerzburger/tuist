import DOT
import Foundation
import GraphViz
import Mockable
import ProjectAutomation
import ServiceContextModule
import TuistCore
import TuistPlugin
import TuistSupport
import XcodeGraph
import XcodeProj
import XCTest

@testable import TuistCoreTesting
@testable import TuistKit
@testable import TuistLoaderTesting
@testable import TuistSupportTesting

final class GraphServiceTests: TuistUnitTestCase {
    var manifestGraphLoader: MockManifestGraphLoading!
    var graphVizMapper: MockGraphToGraphVizMapper!
    var subject: GraphService!

    override func setUp() {
        super.setUp()
        graphVizMapper = MockGraphToGraphVizMapper()
        manifestGraphLoader = .init()

        subject = GraphService(
            graphVizGenerator: graphVizMapper,
            manifestGraphLoader: manifestGraphLoader
        )
    }

    override func tearDown() {
        graphVizMapper = nil
        manifestGraphLoader = nil
        subject = nil
        super.tearDown()
    }

    func test_run_whenDot() async throws {
        try await ServiceContext.withTestingDependencies {
            // Given
            let temporaryPath = try temporaryPath()
            let graphPath = temporaryPath.appending(component: "graph.dot")
            let projectManifestPath = temporaryPath.appending(component: "Project.swift")

            try FileHandler.shared.touch(graphPath)
            try FileHandler.shared.touch(projectManifestPath)
            graphVizMapper.stubMap = Graph()

            given(manifestGraphLoader)
                .load(path: .any)
                .willReturn((.test(), [], MapperEnvironment(), []))

            // When
            try await subject.run(
                format: .dot,
                layoutAlgorithm: .dot,
                skipTestTargets: false,
                skipExternalDependencies: false,
                open: false,
                platformToFilter: nil,
                targetsToFilter: [],
                path: temporaryPath,
                outputPath: temporaryPath
            )
            let got = try FileHandler.shared.readTextFile(graphPath)
            let expected = "graph { }"
            // Then
            XCTAssertEqual(got, expected)
            XCTAssertPrinterOutputContains("""
            Deleting existing graph at \(graphPath.pathString)
            Graph exported to \(graphPath.pathString)
            """)
        }
    }

    func test_run_when_legacyJSON() async throws {
        try await ServiceContext.withTestingDependencies {
            // Given
            let temporaryPath = try temporaryPath()
            let graphPath = temporaryPath.appending(component: "graph.json")
            let projectManifestPath = temporaryPath.appending(component: "Project.swift")

            try FileHandler.shared.touch(graphPath)
            try FileHandler.shared.touch(projectManifestPath)

            given(manifestGraphLoader)
                .load(path: .any)
                .willReturn((.test(), [], MapperEnvironment(), []))

            // When
            try await subject.run(
                format: .legacyJSON,
                layoutAlgorithm: .dot,
                skipTestTargets: false,
                skipExternalDependencies: false,
                open: false,
                platformToFilter: nil,
                targetsToFilter: [],
                path: temporaryPath,
                outputPath: temporaryPath
            )
            let got = try FileHandler.shared.readTextFile(graphPath)

            let result = try JSONDecoder().decode(ProjectAutomation.Graph.self, from: got.data(using: .utf8)!)
            // Then
            XCTAssertEqual(result, ProjectAutomation.Graph(name: "graph", path: "/", projects: [:]))
            XCTAssertPrinterOutputContains("""
            Deleting existing graph at \(graphPath.pathString)
            Graph exported to \(graphPath.pathString)
            """)
        }
    }

    func test_run_when_json() async throws {
        try await ServiceContext.withTestingDependencies {
            // Given
            let temporaryPath = try temporaryPath()
            let graphPath = temporaryPath.appending(component: "graph.json")
            let projectManifestPath = temporaryPath.appending(component: "Project.swift")

            try await fileSystem.touch(graphPath)
            try await fileSystem.touch(projectManifestPath)

            given(manifestGraphLoader)
                .load(path: .any)
                .willReturn((.test(), [], MapperEnvironment(), []))

            // When
            try await subject.run(
                format: .json,
                layoutAlgorithm: .dot,
                skipTestTargets: false,
                skipExternalDependencies: false,
                open: false,
                platformToFilter: nil,
                targetsToFilter: [],
                path: temporaryPath,
                outputPath: temporaryPath
            )
            let got = try await fileSystem.readTextFile(at: graphPath)

            let result = try JSONDecoder().decode(XcodeGraph.Graph.self, from: got.data(using: .utf8)!)
            // Then
            XCTAssertEqual(result, .test())
            XCTAssertPrinterOutputContains("""
            Deleting existing graph at \(graphPath.pathString)
            Graph exported to \(graphPath.pathString)
            """)
        }
    }
}
