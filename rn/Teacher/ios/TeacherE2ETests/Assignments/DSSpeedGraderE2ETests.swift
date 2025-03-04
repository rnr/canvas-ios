//
// This file is part of Canvas.
// Copyright (C) 2022-present  Instructure, Inc.
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

import TestsFoundation
import Core

class DSSpeedGraderE2ETests: E2ETestCase {
    func testSpeedGraderE2E() {
        let users = seeder.createUsers(2)
        let course = seeder.createCourse()
        let student = users[0]
        let teacher = users[1]
        seeder.enrollStudent(student, in: course)
        seeder.enrollTeacher(teacher, in: course)

        let assignmentName = "Assignment 1"
        let assignmentDescription = "This is a description for Assignment 1"
        let assignment = seeder.createAssignment(courseId: course.id, assignementBody: .init(name: assignmentName, description: assignmentDescription, published: true, points_possible: 10))

        logInDSUser(teacher)

        let submission = seeder.createSubmission(courseId: course.id, assignmentId: assignment.id, requestBody:
            .init(submission_type: SubmissionType.online_text_entry, body: "This is a submission body", user_id: student.id))

        DashboardHelper.courseCard(course: course).hit()
        CourseDetailsHelper.cell(type: .assignments).hit()
        sleep(1)
        AssignmentsHelper.assignmentButton(assignment: assignment).hit()
        AssignmentsHelper.Details.viewAllSubmissionsButton.hit()
        AssignmentsHelper.submissionListCell(user: student).hit()
        AssignmentsHelper.SpeedGrader.Segment.grades.hit()
        sleep(1)
        app.find(id: "SpeedGrader.gradeButton", label: "addSolid").hit()
        app.find(label: "Grade", type: .textField).writeText(text: "5")
        app.find(label: "OK").hit()
        AssignmentsHelper.SpeedGrader.doneButton.hit()
        sleep(1)
        pullToRefresh()
        XCTAssertFalse(AssignmentsHelper.submissionListCell(user: student).waitUntil(.vanish).isVisible)
        app.find(labelContaining: "Filter").hit()
        app.find(label: "Graded").hit()
        app.find(label: "Done").hit()
        pullToRefresh()
        XCTAssertTrue(AssignmentsHelper.submissionListCell(user: student).waitUntil(.visible).isVisible)
    }
}
