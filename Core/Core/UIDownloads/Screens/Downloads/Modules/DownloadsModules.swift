//
// This file is part of Canvas.
// Copyright (C) 2023-present  Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import SwiftUI

final class DownloadsModulesViewModel: ObservableObject {

    let modules: [ModuleItem]
    let courseDataModel: CourseStorageDataModel

    init(modules: [ModuleItem], courseDataModel: CourseStorageDataModel) {
        self.modules = modules
        self.courseDataModel = courseDataModel
    }

}

struct DownloadsModules: View {

    // MARK: - Injected -

    @Environment(\.viewController) var controller

    // MARK: - Properties -

    @StateObject var viewModel: DownloadsModulesViewModel
    private let env = AppEnvironment.shared

    private var navigationController: UINavigationController? {
        guard let topViewController = env.topViewController as? UITabBarController,
              let helmSplitViewController = topViewController.viewControllers?.first as? UISplitViewController,
              let navigationController = helmSplitViewController.viewControllers.first as? UINavigationController
             else {
            return nil
        }
        return navigationController
    }

    init(modules: [ModuleItem], courseDataModel: CourseStorageDataModel) {
        let viewModel = DownloadsModulesViewModel(
            modules: modules,
            courseDataModel: courseDataModel
        )
        self._viewModel = .init(wrappedValue: viewModel)
    }

    // MARK: - Views -

    var body: some View {
        content
            .onAppear {
                navigationController?.navigationBar.useGlobalNavStyle()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Modules")
                        .foregroundColor(.white)
                        .font(.semibold16)
                }
            }
    }

    private var content: some View {
        DownloadsContentList {
            ForEach(viewModel.modules, id: \.self) { module in
                DownloadsModuleCellView(
                    viewModel: DownloadsModuleCellViewModel(module: module)
                ).onTapGesture {
                    destination(module: module)
                }
                Divider()
            }
        }
    }

    private func destination(module: ModuleItem) {
        guard let htmlURL = module.htmlURL else {
            return
        }
        navigationController?.navigationBar.useGlobalNavStyle()
        navigationController?.pushViewController(
            CoreHostingController(SUWebView(
                configurator: .init(requestType: .url(htmlURL))
            )),
            animated: true
        )
    }
}
