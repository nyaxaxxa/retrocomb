//
//  StoryManager.swift
//  retrocomb
//
//  Centralises story beats, cutscenes and narrative helpers.
//

import SpriteKit

struct CutsceneDescriptor {
    let title: String
    let lines: [String]
    let nextLevel: Int?
    let returnsToMenu: Bool
}

final class StoryManager {
    static let shared = StoryManager()
    
    private init() {}
    
    private let postmortemMessages: [String] = [
        "Реактор шлюпа перегрузился — останки корабля уступили поясу астероидов.",
        "Сигнал бедствия заглох в шуме космического мусора. Никто не услышал.",
        "Запись бортового журнала завершилась на полуслове: «Если кто найдёт…».",
        "Бортовой ИИ тихо заархивировал данные экипажа и отключился навсегда.",
        "Шлюп развалился, оставив лишь след ионизированных частиц в вакууме.",
        "Стальные панели герметика не выдержали — корабль раскрошился в пыль.",
        "Пулемёты мусорщиков больше не молчат — шлюп стал чьей‑то добычей.",
        "Гравитация планеты оказалась сильнее надежды. Летопись оборвалась.",
        "Спасатели федерации приняли сигнал… но уже слишком поздно.",
        "Последнее изображение — вспышка пламени и строчка «Прощай, экипаж».",
        "Корабль колонистов растворился во всполохах плазмы. История повторилась.",
        "Монстры сомкнули кольцо. Гаснущее поле щита — их последнее зрелище.",
        "База превратилась в руины. Лишь песок будет помнить этот бой.",
        "Радиоканал забит помехами. В ответ — только холодный космос.",
        "Им пришлось остаться на той стороне люка. Радар обнулил их отметки."
    ]
    
    // MARK: - Public helpers
    
    func randomPostmortem() -> String {
        postmortemMessages.randomElement() ?? "История оборвалась среди звёзд."
    }
    
    func cutsceneBefore(level: Int) -> CutsceneDescriptor? {
        switch level {
        case 1:
            return CutsceneDescriptor(
                title: "Колонист «Аврора»",
                lines: [
                    "Огромный корабль колонистов «Аврора» попадает в пояс астероидов.",
                    "Корпус разрывается взрывами, секции одна за другой уходят в огонь.",
                    "Часть экипажа успевает отстыковать аварийный шлюп — твой единственный шанс."
                ],
                nextLevel: 1,
                returnsToMenu: false
            )
        case 2:
            return CutsceneDescriptor(
                title: "Спуск к планете",
                lines: [
                    "Шлюп покидает пояс астероидов и входит в турбулентный слой обломков.",
                    "Системы навигации барахлят, каждый манёвр — борьба за жизнь.",
                    "Внизу видна планета, которая может стать новым домом… если выживешь."
                ],
                nextLevel: 2,
                returnsToMenu: false
            )
        case 3:
            return CutsceneDescriptor(
                title: "Орбита мусорщиков",
                lines: [
                    "На орбите уже кружат корабли мусорщиков. Они засекли твой шлюп.",
                    "Им не нужен выживший, им нужен металл. Придётся прорываться.",
                    "Собери ресурсы, обмани радары — доберись до безопасной траектории."
                ],
                nextLevel: 3,
                returnsToMenu: false
            )
        case 4:
            return CutsceneDescriptor(
                title: "Прыжок к поверхности",
                lines: [
                    "Шлюп входит в атмосферу. Датчики зашкаливают, топливо на исходе.",
                    "Любая ошибка — пылающий кратер. Тебе нужно посадить корабль идеально.",
                    "Внизу — неизвестная планета, где тебе предстоит построить новый дом."
                ],
                nextLevel: 4,
                returnsToMenu: false
            )
        case 5:
            return CutsceneDescriptor(
                title: "Строительство базы",
                lines: [
                    "Шлюп приземлился. Корпус повреждён, но ты жив.",
                    "Коммуникации с федерацией оборваны. Нужно построить базу и выжить.",
                    "Сканеры фиксируют странные сигнатуры в песках — держи оборону."
                ],
                nextLevel: 5,
                returnsToMenu: false
            )
        case 6:
            return CutsceneDescriptor(
                title: "Сердце комплекса",
                lines: [
                    "Твари прорвали периметр. Внутренние коридоры полны хаоса.",
                    "Единственный способ выбраться — удержать позицию, пока не придёт помощь.",
                    "Сражайся изо всех сил. Каждый уничтоженный монстр — ещё один шанс на спасение."
                ],
                nextLevel: 6,
                returnsToMenu: false
            )
        default:
            return nil
        }
    }
    
    func cutsceneAfter(level: Int, victory: Bool) -> CutsceneDescriptor? {
        switch level {
        case 1:
            return CutsceneDescriptor(
                title: "Дрейф через обломки",
                lines: [
                    "Шлюп проскальзывает через последние глыбы астероидов.",
                    "Виднеются обломки «Авроры», сгорающие в плазме.",
                    "Впереди — опасное снижение к планете."
                ],
                nextLevel: 2,
                returnsToMenu: false
            )
        case 2:
            return CutsceneDescriptor(
                title: "Орбитальная дуэль",
                lines: [
                    "Шлюп выныривает из облаков. На радарах — корабли мусорщиков.",
                    "Они хотят разобрать твой шлюп на запчасти.",
                    "Придётся дать бой прямо на орбите."
                ],
                nextLevel: 3,
                returnsToMenu: false
            )
        case 3:
            return CutsceneDescriptor(
                title: "Сквозь атмосферу",
                lines: [
                    "Манёвром отчаянного пилота ты ушёл от мусорщиков.",
                    "Планета уже близко, очертания континентов сияют в огне.",
                    "Настало время совершить посадку — единственную и последнюю."
                ],
                nextLevel: 4,
                returnsToMenu: false
            )
        case 4:
            return CutsceneDescriptor(
                title: "Новый форпост",
                lines: [
                    "Шлюп опустился на поверхность. Вокруг — океан песка и древних руин.",
                    "Без связи с федерацией нужно построить базу и наладить энергию.",
                    "Ресурсы ограничены, ночь близко — готовься к обороне."
                ],
                nextLevel: 5,
                returnsToMenu: false
            )
        case 5:
            if victory {
                return CutsceneDescriptor(
                    title: "Разлом под базой",
                    lines: [
                        "Сканеры глубин обнаружили гигантские тоннели под базой.",
                        "Твари вырываются из недр планеты. Рубеж обороны падает.",
                        "Отступай внутрь комплекса и удержись до последнего патрона!"
                    ],
                    nextLevel: 6,
                    returnsToMenu: false
                )
            } else {
                return CutsceneDescriptor(
                    title: "Штурм бреши",
                    lines: [
                        "Периметр пал. Монстры разрывают стены базы.",
                        "Выжившие отступают в центральный модуль.",
                        "Закрывай гермодвери и готовь оружие — сейчас решается всё."
                    ],
                    nextLevel: 6,
                    returnsToMenu: false
                )
            }
        case 6:
            if victory {
                return CutsceneDescriptor(
                    title: "Спасение федерации",
                    lines: [
                        "Сигнал бедствия принят. Фрегат федерации входит в атмосферу.",
                        "Спасательная команда добирается до тебя сквозь дым и огонь.",
                        "Выжившие эвакуированы. История «Авроры» не закончилась напрасно."
                    ],
                    nextLevel: nil,
                    returnsToMenu: true
                )
            }
            return nil
        default:
            return nil
        }
    }
    
    @MainActor
    func scene(for level: Int, size: CGSize) -> SKScene {
        switch level {
        case 1: return Level1Scene(size: size)
        case 2: return Level2Scene(size: size)
        case 3: return Level3Scene(size: size)
        case 4: return Level4Scene(size: size)
        case 5: return Level5Scene(size: size)
        case 6: return Level6Scene(size: size)
        default: return MenuScene(size: size)
        }
    }
    
    // MARK: - Presentation helpers
    
    func presentPreLevelCutscene(from scene: SKScene, level: Int) {
        guard let descriptor = cutsceneBefore(level: level) else { return }
        presentCutscene(from: scene, descriptor: descriptor)
    }
    
    func presentPostLevelCutscene(from scene: SKScene, level: Int, victory: Bool) {
        guard let descriptor = cutsceneAfter(level: level, victory: victory) else { return }
        presentCutscene(from: scene, descriptor: descriptor)
    }
    
    func presentFinalRescue(from scene: SKScene) {
        guard let descriptor = cutsceneAfter(level: 6, victory: true) else { return }
        presentCutscene(from: scene, descriptor: descriptor)
    }
    
    private func presentCutscene(from scene: SKScene, descriptor: CutsceneDescriptor) {
        guard let view = scene.view else { return }
        let size = scene.size
        let scale = scene.scaleMode
        let cutscene = CutsceneScene(size: size, descriptor: descriptor) { [weak self] in
            guard let self = self else { return nil }
            if let next = descriptor.nextLevel {
                let nextScene = self.scene(for: next, size: size)
                nextScene.scaleMode = scale
                return nextScene
            }
            if descriptor.returnsToMenu {
                let menu = MenuScene(size: size)
                menu.scaleMode = scale
                return menu
            }
            return nil
        }
        cutscene.scaleMode = scale
        view.presentScene(cutscene, transition: SKTransition.fade(withDuration: 0.6))
    }
}


