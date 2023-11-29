import os
import cv2


def parse_annotation(annotation_line):
    parts = annotation_line.strip().split(":")
    image_name = parts[0]
    objects = parts[1].split(";")
    annotations = []

    for obj in objects:
        obj_parts = obj.strip().split(",")
        # Check if the line contains coordinates and class name
        if len(obj_parts) >= 6:
            # The first two items might be tags like MISC_SIGNS, VISIBLE, etc.
            # The next four are the bounding box coordinates, and the rest are the class name
            try:
                bbox = [float(x) for x in obj_parts[-6:-2]]
            except:
                print()
            class_name = "_".join(obj_parts[-2:]).replace(" ", "")
            annotations.append((bbox, class_name))

    return image_name, annotations


def convert_to_yolo_format(bbox, img_width, img_height):
    x_center = (bbox[0] + bbox[2]) / 2.0
    y_center = (bbox[1] + bbox[3]) / 2.0
    width = bbox[0] - bbox[2]
    height = bbox[1] - bbox[3]
    return [
        x_center / img_width,
        y_center / img_height,
        width / img_width,
        height / img_height,
    ]


def process_annotations(label_file_path, images_dir, output_dir, class_mapping):
    next_class_id = 0

    with open(label_file_path, "r") as file:
        for line in file:
            image_name, annotations = parse_annotation(line)
            image_path = os.path.join(images_dir, image_name)
            image = cv2.imread(image_path)
            if image is None:
                continue  # Skip if the image is not found
            img_height, img_width = image.shape[:2]

            for bbox, class_name in annotations:
                if class_name not in class_mapping:
                    class_mapping[class_name] = next_class_id
                    next_class_id += 1

                yolo_bbox = convert_to_yolo_format(bbox, img_width, img_height)
                yolo_line = (
                    f"{class_mapping[class_name]} {' '.join(map(str, yolo_bbox))}\n"
                )

                output_path = os.path.join(
                    output_dir, os.path.splitext(image_name)[0] + ".txt"
                )
                with open(output_path, "a") as output_file:
                    output_file.write(yolo_line)
    with open(os.path.join(output_dir, "classes.txt"), "w") as class_file:
        for class_name, class_id in sorted(
            class_mapping.items(), key=lambda item: item[1]
        ):
            class_file.write(f"{class_name}\n")


mapping = {}
# Usage example:
process_annotations(
    "path_to_annotation_file",
    "path_to_iamges",
    "output_dir_for_generated_labels",
    mapping,
)

