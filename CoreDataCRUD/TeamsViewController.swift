//
//  TeamsViewController.swift
//  CoreDataCRUD
//
//  Created by Hank.Lee on 10/07/2019.
//  Copyright © 2019 hyeongkyu. All rights reserved.
//

import UIKit
import CoreData

class TeamsViewController: UITableViewController {
    var person: Person?
    
    lazy var teams: [Team] = {
        let request = NSFetchRequest<Team>(entityName: "Team")
        let teams = try? persistentContainer.viewContext.fetch(request)
        return teams ?? []
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Teams"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Menu", style: .plain, target: self, action: #selector(showMenu))
        
        NotificationCenter.default.addObserver(self, selector: #selector(didManagedObjectChange(notification:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
    }
    
    @objc private func didManagedObjectChange(notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let objects = userInfo[NSUpdatedObjectsKey] as? Set<Team>
                ?? userInfo[NSInsertedObjectsKey] as? Set<Team>
                ?? userInfo[NSDeletedObjectsKey] as? Set<Team>
            else {
                return
        }
        
        if objects.isEmpty { return }
        
        tableView.reloadData()
    }
    
    lazy var menus: [Menu] = [
        Menu(title: "New Team", handler: { [weak self] in
            self?.showTeamForm()
        })
    ]
    
    @objc private func showMenu() {
        let alert = UIAlertController(title: "Menu", message: nil, preferredStyle: .actionSheet)
        menus.forEach { (menu) in
            alert.addAction(UIAlertAction(title: menu.title, style: .default, handler: { (action) in
                menu.handler?()
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func showTeamForm(team: Team? = nil) {
        let alert = UIAlertController(title: "New Team", message: nil, preferredStyle: .alert)
        weak var textField: UITextField?
        
        alert.addTextField { (_textField) in
            textField = _textField
            textField?.text = team?.value(forKey: "name") as? String
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] (action) in
            let name = textField?.text ?? ""
            if name.isEmpty { return }
            if let team = team {
                team.name = name
                try? persistentContainer.viewContext.save()
            } else {
                self?.createNewTeam(name: name)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func createNewTeam(name: String) {
        let managedContext = persistentContainer.viewContext
        let team = Team(context: managedContext)
        team.name = name
        do {
            try managedContext.save()
            teams.append(team)
        } catch {
            print("save error = \(error)")
        }
    }
    
    private func teamMenus(team: Team) -> [Menu] {
        return [
            Menu(title: "Rename", handler: { [weak self] in
                self?.showTeamForm(team: team)
            }),
            Menu(title: "Delete", handler: { [weak self] in
                do {
                    try team.validateForDelete()
                    self?.teams.removeAll { $0 == team }
                    persistentContainer.viewContext.delete(team)
                    try persistentContainer.viewContext.save()
                } catch {
                    // do nothing
                }
            })
        ]
    }
    
    private func showTeamMenu(team: Team) {
        let alertController = UIAlertController(title: team.name, message: nil, preferredStyle: .actionSheet)
        let menus = teamMenus(team: team)
        menus.forEach { (menu) in
            alertController.addAction(UIAlertAction(title: menu.title, style: .default, handler: { (action) in
                menu.handler?()
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teams.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = teams[indexPath.row].value(forKey: "name") as? String
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let person = person {
            person.team = teams[indexPath.row]
            try? persistentContainer.viewContext.save()
        } else {
            showTeamMenu(team: teams[indexPath.row])
        }
    }
}
